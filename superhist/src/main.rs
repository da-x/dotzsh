use structopt::StructOpt;
use std::{collections::hash_map, path::PathBuf};
use std::io::Write;
use std::fs::{OpenOptions, File};
use std::io::{BufReader, BufRead};
use std::io::BufWriter;
use thiserror::Error;
use regex::Regex;
use file_lock::FileLock;
use serde::{Serialize, Deserialize};
use xz2::read::XzDecoder;
use xz2::write::XzEncoder;
use std::collections::HashMap;
use filetime::FileTime;
use futures::StreamExt;
use futures::FutureExt;
use unicode_width::UnicodeWidthChar;

#[derive(Error, Debug)]
enum Error {
    #[error("I/O error; {0}")]
    IoError(#[from] std::io::Error),
    #[error("env var error; {0}")]
    VarError(#[from] std::env::VarError),
    #[error("json error; {0}")]
    CsvError(#[from] serde_json::Error),
    #[error("CrossTerm error; {0}")]
    CrossTermError(#[from] crossterm::ErrorKind),
    #[error("invalid parameters")]
    InvalidParams,
}

type UnixTime = u64;
pub type Tty = File;

#[derive(Debug, Deserialize, Serialize)]
pub enum Payload {
    Start,
    Command {
        text: String,
        workdir: String,
    },
    ExitCode(u32),
}

#[derive(Debug, Deserialize, Serialize, Clone)]
pub struct Procedure {
    command: String,
}

pub type Workdir = String;

#[derive(Debug, Deserialize, Serialize, Default, Clone)]
pub struct Procedures {
    by_workdir: HashMap<Workdir, Vec<(String, Procedure)>>,
}

impl Procedures {
    fn add_command(&mut self, alias: Option<String>, workdir_path: String, command: String) -> usize {
        let workdir = match self.by_workdir.entry(workdir_path) {
            hash_map::Entry::Vacant(v) => v.insert(Default::default()),
            hash_map::Entry::Occupied(o) => o.into_mut(),
        };

        let alias = match alias {
            Some(s) => s,
            None => {
                // Allocate an unused 'cmd' alias
                let mut alias = None;
                for i in 1.. {
                    let candidate = format!("cmd{}", i);
                    let mut found = false;
                    for v in workdir.iter() {
                        if v.0 == candidate {
                            found = true;
                            break;
                        }
                    }
                    if !found {
                        alias = Some(candidate);
                        break;
                    }
                }
                alias.unwrap()
            }
        };

        workdir.push((alias, Procedure { command } ));
        workdir.len()
    }
}

#[derive(Debug, Deserialize, Serialize)]
pub struct Event {
    pub timestamp: UnixTime,
    pub idx: u64,
    pub terminal: String,
    pub payload: Payload,
}

#[derive(StructOpt, Debug)]
enum Command {
    Archive,
    Import {
        #[structopt(short = "p")]
        hist_file: PathBuf,
    },
    FC {
        #[structopt(short = "w")]
        workdir: Option<String>,

        #[structopt(short = "s")]
        start_nr: u64,

        #[structopt(short = "f")]
        fetch: Option<u64>,
    },
    Add {
        #[structopt(short = "x")]
        timestamp: u64,

        #[structopt(short = "i")]
        idx: u64,

        #[structopt(short = "t")]
        terminal: String,

        #[structopt(short = "c")]
        command: Option<String>,

        #[structopt(short = "w")]
        workdir: Option<String>,

        #[structopt(short = "e")]
        exit_code: Option<u32>,

        #[structopt(short = "s")]
        start: bool,
    },
    ProcAdd {
        #[structopt(short = "a")]
        alias: Option<String>,

        #[structopt(short = "c")]
        command: String,

        #[structopt(short = "w")]
        workdir: String,

        #[structopt(short = "i")]
        interactive: bool,

        #[structopt(short = "p")]
        prev_result: Option<String>,
    },
    ProcPick {
        #[structopt(short = "w")]
        workdir: String,

        #[structopt(short = "p")]
        prev_result: Option<String>,
    },
}

#[derive(StructOpt, Debug)]
struct Opt {
    #[structopt(short = "d")]
    debug: bool,

    #[structopt(long = "root")]
    root: PathBuf,

    #[structopt(subcommand)]
    command: Command,
}

lazy_static::lazy_static! {
    static ref RE: Regex = Regex::new(": ([0-9]+) (([^:]*):)?0;(.*)$").unwrap();
}

enum ProcedureState {
    Add { alias: Option<String>, command: String },
    Pick,
}

struct ProcedureMode {
    mtime: Option<FileTime>,
    info: Procedures,
    workdir_path: String,
    state: ProcedureState,
    selected: usize,
    sequence: Vec<String>,
    lines: ExpandingBottomScreen,
}

#[derive(Default)]
struct ExpandingBottomScreen {
    lines_scolled: usize,
    lines_printed: usize,
    term_size: (u16, u16),
    col_x: usize,
    indent_x: usize,
    end_of_line: Option<usize>,
}

impl ExpandingBottomScreen {
    fn start(&mut self, tty: &mut Tty, term_size: (u16, u16)) -> Result<(), Error> {
        use crossterm::QueueableCommand;
        self.lines_printed = 0;
        self.term_size = term_size;
        self.col_x = 0;

        if self.lines_scolled > 0 {
            tty.queue(crossterm::cursor::MoveToPreviousLine(self.lines_scolled as u16))?;
        }

        Ok(())
    }

    fn set_indent_x(&mut self, indent_x: usize, tty: &mut Tty) -> Result<(), Error> {
        self.end_of_line_flush(tty, false)?;
        self.indent_x = indent_x;

        Ok(())
    }

    fn start_line(&mut self, tty: &mut Tty) -> Result<(), Error> {
        self.end_of_line_flush(tty, false)?;
        self.col_x = self.indent_x;

        Ok(())
    }

    fn end_of_line_flush(&mut self, tty: &mut Tty, _last_printed: bool) -> Result<(), Error> {
        use crossterm::QueueableCommand;

        tty.queue(crossterm::terminal::Clear(crossterm::terminal::ClearType::UntilNewLine))?;

        if let Some(_) = self.end_of_line {
            self.end_of_line = None;
            self.lines_printed += 1;
            tty.queue(crossterm::style::Print("\r\n"))?;
        }

        Ok(())
    }

    fn end_line(&mut self, _tty: &mut Tty) -> Result<(), Error> {
        if self.col_x != 0  {
            self.end_of_line = Some(self.col_x);
        }

        self.col_x = 0;

        Ok(())
    }

    fn print(&mut self, s: &str, tty: &mut Tty) -> Result<(), Error> {
        self.end_of_line_flush(tty, false)?;
        use crossterm::QueueableCommand;

        for c in s.chars() {
            if self.col_x == self.term_size.0 as usize {
                self.col_x = 0;
                self.lines_printed += 1;
            }

            if self.col_x == 0 {
                self.col_x = self.indent_x;
                tty.queue(crossterm::style::Print(format!("{:>width$}", "", width=self.indent_x)))?;
            }

            tty.queue(crossterm::style::Print(c))?;

            self.col_x += c.width().unwrap_or(1);
            if self.col_x > self.term_size.0 as usize {
                self.lines_printed += 1;
                self.col_x = self.term_size.0 as usize;
            }
        }

        Ok(())
    }

    fn end(&mut self, tty: &mut Tty) -> Result<(), Error> {
        use crossterm::QueueableCommand;

        self.end_of_line_flush(tty, true)?;

        for _ in self.lines_printed..self.lines_scolled {
            tty.queue(crossterm::style::ResetColor)?;
            tty.queue(crossterm::terminal::Clear(crossterm::terminal::ClearType::UntilNewLine))?;
            tty.queue(crossterm::style::Print("\r\n"))?;
        }

        self.lines_scolled = std::cmp::max(self.lines_printed, self.lines_scolled);

        Ok(())
    }

    fn clear(&self, tty: &mut Tty) -> Result<(), Error> {
        use crossterm::QueueableCommand;

        if self.lines_scolled > 0 {
            tty.queue(crossterm::cursor::MoveToPreviousLine(self.lines_scolled as u16))?;
            tty.queue(crossterm::style::ResetColor)?;
            for _ in 0..self.lines_scolled {
                tty.queue(crossterm::terminal::Clear(crossterm::terminal::ClearType::UntilNewLine))?;
                tty.queue(crossterm::style::Print("\r\n"))?;
            }
            tty.queue(crossterm::cursor::MoveToPreviousLine(self.lines_scolled as u16))?;
        } else {
            tty.queue(crossterm::style::ResetColor)?;
            tty.queue(crossterm::style::Print("\r"))?;
            tty.queue(crossterm::terminal::Clear(crossterm::terminal::ClearType::UntilNewLine))?;
        }

        Ok(())
    }
}

#[derive(Default, Deserialize, Serialize)]
struct SelectionState {
    mode: String,
    selected: usize,
    sequence: Vec<String>,
    exec_queue: Vec<(String, String)>,
}

impl SelectionState {
    fn save(&mut self, proc_mode: &ProcedureMode) {
        if let Some(procs) = proc_mode.info.by_workdir.get(&proc_mode.workdir_path) {
            let mut with_selected = false;
            for seq in proc_mode.sequence.iter() {
                for (idx, proc) in procs.iter().enumerate() {
                    if &proc.0 == seq {
                        if idx == proc_mode.selected {
                            with_selected = true;
                        }
                        self.exec_queue.push((proc.0.clone(), proc.1.command.clone()));
                        break;
                    }
                }
            }
            self.selected = proc_mode.selected;
            self.sequence = proc_mode.sequence.clone();

            if !with_selected {
                for (idx, proc) in procs.iter().enumerate() {
                    if idx == proc_mode.selected {
                        self.exec_queue.push((proc.0.clone(), proc.1.command.clone()));
                        break;
                    }
                }
            }
        }
    }
}

pub struct SuperHist {
    root: PathBuf,
    selection_state: SelectionState,
}

use crossterm::{
    cursor,
    execute,
    event::{self, EventStream},
    terminal,
};

pub(crate) static SELECTION_BACKGROUND : crossterm::style::Color = crossterm::style::Color::Rgb { r: 50, g: 50, b: 50 };
pub(crate) static SEPARATOR : crossterm::style::Color = crossterm::style::Color::Rgb { r: 50, g: 50, b: 50 };
pub(crate) static ALIAS : crossterm::style::Color = crossterm::style::Color::Rgb { r: 255, g: 255, b: 0 };
pub(crate) static ADDING_HEADER : crossterm::style::Color = crossterm::style::Color::Rgb { r: 0, g: 255, b: 255 };
pub(crate) static SEQ_BOX_BRACKET : crossterm::style::Color = crossterm::style::Color::Rgb { r: 0, g: 120, b: 0 };
pub(crate) static SEQ_BOX_INDEX : crossterm::style::Color = crossterm::style::Color::Rgb { r: 0, g: 255, b: 0 };
pub(crate) static COMMAND_TEXT : crossterm::style::Color = crossterm::style::Color::Rgb { r: 180, g: 180, b: 180 };

fn term_off(tty: &mut Tty) -> Result<(), Error> {
    execute!(tty, cursor::Show)?;
    terminal::disable_raw_mode()?;
    Ok(())
}

fn term_on(tty: &mut Tty) -> Result<(), Error> {
    terminal::enable_raw_mode()?;
    execute!(tty, cursor::Hide)?;
    Ok(())
}

impl ProcedureMode {
    fn load_selection_state(&mut self, selection_state: SelectionState) {
        self.selected = selection_state.selected;
        self.sequence = selection_state.sequence.clone();
    }
}

impl SuperHist {
    fn new(path: PathBuf) -> Self {
        SuperHist {
            root: path,
            selection_state: Default::default(),
        }
    }

    fn lock_path(&self) -> PathBuf {
        self.root.join("lock")
    }

    fn main_db_file(&self) -> PathBuf {
        self.root.join("db.json")
    }

    fn procedures_file(&self) -> PathBuf {
        self.root.join("procedures.json")
    }

    fn procedures_tmp_file(&self) -> PathBuf {
        self.root.join("procedures.json.tmp")
    }

    fn archive_dir(&self) -> PathBuf {
        self.root.join("archive")
    }

    fn archive_file(&self)  -> Result<PathBuf, Error>  {
        use chrono::Utc;
        let s = format!("{}-{}.xz",
            Utc::now().format("%F-%H-%M-%S"),
            hostname::get()?.into_string().unwrap());
        Ok(self.archive_dir().join(s))
    }

    // Lock the main lockfile using fcntl
    fn lock(&self) -> Result<FileLock, Error> {
        let path = self.lock_path();
        if !path.exists() {
            let mut file = std::fs::File::create(&path)?;
            file.write_all(b"")?;
        }
        Ok(FileLock::lock(path.to_str().unwrap(), true, true)?)
    }

    /// Take current file, reverse its record and keep it xz-compressed under archive/
    fn archive(&self) -> Result<(), Error> {
        std::fs::create_dir_all(self.archive_dir())?;

        let lock = self.lock()?;
        let archive = self.archive_file()?;

        let writer = BufWriter::new(File::create(archive)?);
        let mut compressor = XzEncoder::new(writer, 9);

        {
            let reader = BufReader::new(File::open(self.main_db_file())?);
            let mut vx = vec![];
            for line in reader.lines() {
                vx.push(line?);
            }

            for line in vx.iter().rev() {
                compressor.write(line.as_bytes())?;
                compressor.write("\n".as_bytes())?;
            }
            compressor.flush()?;
        }

        OpenOptions::new().write(true).truncate(true).open(self.main_db_file())?;

        std::fs::remove_file(self.main_db_file())?;

        lock.unlock()?;
        Ok(())
    }

    /// Import an old zsh history file
    fn import(&self, pathname: &PathBuf) -> Result<(), Error> {
        let reader = BufReader::new(File::open(pathname)?);

        // Read current file
        lazy_static::lazy_static! {
            static ref RE: Regex = Regex::new("^: ([0-9]+) ([^:]*):0;((.|\n)*)$").unwrap();
        }

        let mut bunch = String::new();
        let mut open = false;
        let mut bunches = vec![];

        for line in reader.lines() {
            if let Ok(line) = line {
                if line.ends_with("\\") {
                    bunch += &line[0 .. line.len() - 1];
                    bunch += "\n";
                    open = true;
                    continue;
                }
                if open {
                    bunch += &line;
                    bunches.push(std::mem::replace(&mut bunch, String::new()));
                    open = false;
                } else {
                    bunches.push(line.to_owned());
                }
            }
        }

        let mut events = vec![];
        for bunch in bunches.iter() {
            if let Some(captures) = RE.captures(&bunch) {
                let ts = captures.get(1).unwrap().as_str();
                let workdir = captures.get(2).unwrap().as_str();
                let command = captures.get(3).unwrap().as_str();
                let event = Event {
                    timestamp: ts.parse().unwrap(),
                    idx: 0,
                    terminal: "/dev/pts/999".to_owned(),
                    payload: Payload::Command {
                        text: command.to_owned(),
                        workdir: workdir.to_owned(),
                    }
                };
                events.push(event);
            }
        }

        self.add(events)?;

        Ok(())
    }

    fn enter_proc_mode(&mut self, state: ProcedureState, workdir_path: String, pick_result: Option<SelectionState>) -> Result<(), Error> {
        use crossterm::QueueableCommand;

        let (procedures, mtime) = self.with_procedures(move |procedures, _save| {
            procedures.clone()
        })?;

        let mut mode = ProcedureMode {
            info: procedures,
            workdir_path,
            state,
            mtime,
            sequence: vec![],
            selected: 0,
            lines: Default::default(),
        };

        if let Some(pick_result) = pick_result {
            mode.load_selection_state(pick_result);
        }

        let mut tty = std::fs::OpenOptions::new().write(true).open("/dev/tty")?;
        term_on(&mut tty)?;
        tty.queue(crossterm::style::Print("\r\n"))?;

        let e = tokio::runtime::Builder::new_current_thread()
            .enable_all()
            .build()
            .unwrap()
            .block_on(async {
                self.proc_mode(&mut mode, &mut tty).await
            });

        tty.queue(crossterm::cursor::MoveToPreviousLine(1))?;
        term_off(&mut tty)?;

        serde_json::to_writer(std::io::stdout(), &self.selection_state)?;

        e
    }

    fn proc_add(&mut self, alias: Option<String>, command: String, workdir_path: String) -> Result<(), Error> {
        self.with_procedures(move |procedures, save| {
            procedures.add_command(alias, workdir_path, command);
            *save = true;
        })?;

        Ok(())
    }

    async fn proc_mode(&mut self, proc_mode: &mut ProcedureMode, tty: &mut Tty) -> Result<(), Error> {
        let mut reader = EventStream::new();

        loop {
            self.proc_mode_redraw(proc_mode, tty)?;
            let mut flush_events = false;

            if let Some(mtime) = proc_mode.mtime {
                if self.are_procedures_updated(mtime)? {
                    let (info, mtime) = self.with_procedures(move |procedures, _| procedures.clone())?;
                    proc_mode.info = info;
                    proc_mode.mtime = mtime;
                    flush_events = true;
                }
            }

            futures::select! {
                maybe_event = reader.next().fuse() => {
                    match maybe_event {
                        Some(Ok(event::Event::Mouse{..})) => continue,
                        Some(Ok(event)) => {
                            if flush_events {
                                continue;
                            }
                            let b = self.proc_mode_event(proc_mode, event)?;
                            if !b {
                                break;
                            }
                        }
                        Some(Err(_)) => {
                            break;
                        }
                        None => {}
                    }
                }
            }
        }

        proc_mode.lines.clear(tty)?;
        tty.flush()?;

        Ok(())
    }

    fn proc_mode_save(&mut self, proc_mode: &mut ProcedureMode) -> Result<(), Error> {
        let info = proc_mode.info.clone();
        let (_, mtime) = self.with_procedures(move |procedures, save| {
            *procedures = info;
            *save = true;
        })?;
        proc_mode.mtime = mtime;

        Ok(())
    }

    fn proc_mode_event(&mut self, proc_mode: &mut ProcedureMode, event: event::Event) -> Result<bool, Error> {
        match event {
            event::Event::Key(key_event) => {
                match key_event.code {
                    event::KeyCode::Char('q') => {
                        self.selection_state.save(proc_mode);
                        return Ok(false);
                    }
                    event::KeyCode::Up => {
                        proc_mode.selected = proc_mode.selected.saturating_sub(1);
                    }
                    event::KeyCode::Down => {
                        if let Some(procs) = proc_mode.info.by_workdir.get(&proc_mode.workdir_path) {
                            proc_mode.selected = std::cmp::min(proc_mode.selected + 1, procs.len().saturating_sub(1));
                        }
                    }
                    event::KeyCode::Char(' ') => {
                        if let Some(procs) = proc_mode.info.by_workdir.get_mut(&proc_mode.workdir_path) {
                            let selected = proc_mode.selected;
                            if selected < procs.len() {
                                if proc_mode.sequence.iter().find(|x| x == &&procs[selected].0).is_none() {
                                    proc_mode.sequence.push(procs[selected].0.clone());
                                } else {
                                    proc_mode.sequence.retain(|x| x != &procs[selected].0);
                                }
                            }
                        }
                    }
                    event::KeyCode::Delete => {
                        if let Some(procs) = proc_mode.info.by_workdir.get_mut(&proc_mode.workdir_path) {
                            if proc_mode.selected < procs.len() {
                                let selected = proc_mode.selected;
                                proc_mode.sequence.retain(|x| x != &procs[selected].0);
                                procs.remove(proc_mode.selected);
                                proc_mode.selected = std::cmp::min(proc_mode.selected, procs.len().saturating_sub(1));
                            }
                        }

                        self.proc_mode_save(proc_mode)?;
                    }
                    event::KeyCode::Insert => {
                        match std::mem::replace(&mut proc_mode.state, ProcedureState::Pick) {
                            ProcedureState::Pick => {}
                            ProcedureState::Add{ command, alias } => {
                                let nr = proc_mode.info.add_command(alias.clone(), proc_mode.workdir_path.clone(), command);
                                proc_mode.selected = nr - 1;
                                self.proc_mode_save(proc_mode)?;
                            }
                        }
                    }
                    event::KeyCode::Enter => {
                        if let Some(procs) = proc_mode.info.by_workdir.get_mut(&proc_mode.workdir_path) {
                            match &proc_mode.state {
                                ProcedureState::Pick => {
                                    self.selection_state.save(&proc_mode);
                                    self.selection_state.mode = "execute".to_owned();
                                    return Ok(false);
                                }
                                ProcedureState::Add{ command, .. } => {
                                    let selected = proc_mode.selected;
                                    if selected < procs.len() {
                                        procs[selected].1.command = command.clone();
                                        proc_mode.state = ProcedureState::Pick;
                                        self.proc_mode_save(proc_mode)?;
                                    }
                                }
                            }
                        }
                    }
                    _ => {}
                }
            }
            _ => {},
        }

        Ok(true)
    }

    fn proc_mode_redraw(&mut self, proc_mode: &mut ProcedureMode, tty: &mut Tty) -> Result<(), Error> {
        let term_size = terminal::size()?;
        use crossterm::QueueableCommand;
        use crossterm::style;

        proc_mode.lines.start(tty, term_size)?;

        let (name_column_width, seq_len) = if let Some(procs) = proc_mode.info.by_workdir.get(&proc_mode.workdir_path) {
            let mut name_column_width = 1;
            let seq_len = format!("{}", (proc_mode.sequence.len())).len();

            for proc in procs {
                name_column_width = std::cmp::max(name_column_width, proc.0.len());
            }

            (name_column_width, seq_len)
        } else {
            (0, 1)
        };

        proc_mode.lines.set_indent_x(0, tty)?;

        tty.queue(style::ResetColor)?;

        let indent_x = name_column_width + 1 + seq_len + 3;
        match &proc_mode.state {
            ProcedureState::Pick => { }
            ProcedureState::Add{ command, .. } => {
                proc_mode.lines.start_line(tty)?;
                tty.queue(style::SetForegroundColor(SEPARATOR))?;
                proc_mode.lines.print(&"-".repeat(term_size.0 as usize), tty)?;
                proc_mode.lines.end_line(tty)?;

                proc_mode.lines.start_line(tty)?;
                tty.queue(style::SetForegroundColor(ADDING_HEADER))?;
                proc_mode.lines.print(&format!("{:width$}", "[adding] ", width=indent_x), tty)?;
                tty.queue(style::SetForegroundColor(COMMAND_TEXT))?;
                proc_mode.lines.print(&command, tty)?;
                proc_mode.lines.end_line(tty)?;
            }
        }

        proc_mode.lines.set_indent_x(0, tty)?;
        tty.queue(style::SetForegroundColor(SEPARATOR))?;

        proc_mode.lines.start_line(tty)?;
        proc_mode.lines.print(&"-".repeat(term_size.0 as usize), tty)?;
        proc_mode.lines.end_line(tty)?;

        if let Some(procs) = proc_mode.info.by_workdir.get(&proc_mode.workdir_path) {
            proc_mode.lines.set_indent_x(indent_x, tty)?;

            for (index, proc) in procs.iter().enumerate() {
                proc_mode.lines.start_line(tty)?;

                if index == proc_mode.selected {
                    tty.queue(style::SetBackgroundColor(SELECTION_BACKGROUND))?;
                } else {
                    tty.queue(style::ResetColor)?;
                }

                tty.queue(style::SetForegroundColor(ALIAS))?;
                tty.queue(style::Print(format!("{:>width$} ", proc.0, width=name_column_width)))?;

                let mut found = false;
                for (seq_idx, seq) in proc_mode.sequence.iter().enumerate() {
                    if seq == &proc.0 {
                        tty.queue(style::SetForegroundColor(SEQ_BOX_BRACKET))?;
                        tty.queue(style::Print(format!("[")))?;
                        tty.queue(style::SetForegroundColor(SEQ_BOX_INDEX))?;
                        tty.queue(style::Print(format!("{:>width$}", seq_idx + 1, width=seq_len)))?;
                        tty.queue(style::SetForegroundColor(SEQ_BOX_BRACKET))?;
                        tty.queue(style::Print(format!("] ")))?;
                        found = true;
                        break;
                    }
                }
                if !found {
                    tty.queue(style::Print(format!(" {:>width$}  ", "", width=seq_len)))?;
                }

                tty.queue(style::SetForegroundColor(COMMAND_TEXT))?;

                proc_mode.lines.print(&proc.1.command, tty)?;
                proc_mode.lines.end_line(tty)?;
            }
        }

        proc_mode.lines.end(tty)?;
        tty.flush()?;

        Ok(())
    }

    fn are_procedures_updated(&self, file_time: FileTime) -> Result<bool, Error> {
        let procedures_file = self.procedures_file();
        if let Ok(metadata) = std::fs::metadata(&procedures_file) {
            let current_mtime = FileTime::from_last_modification_time(&metadata);

            Ok(current_mtime != file_time)
        } else {
            Ok(false)
        }
    }

    fn with_procedures<R>(&self, f: impl FnOnce(&mut Procedures, &mut bool) -> R) -> Result<(R, Option<FileTime>), Error> {
        let lock = self.lock()?;
        let procedures_file = self.procedures_file();

        let (mut procedures, mut opt_mtime) = if let Ok(file) = OpenOptions::new().read(true).open(&procedures_file) {
            let metadata = std::fs::metadata(&procedures_file)?;
            let mtime = FileTime::from_last_modification_time(&metadata);
            (serde_json::from_reader(BufReader::new(file))?, Some(mtime))
        } else {
            Default::default()
        };

        let mut save = false;
        let r = f(&mut procedures, &mut save);
        if save {
            let procedures_tmp_file = self.procedures_tmp_file();
            let file = OpenOptions::new().create(true).write(true).truncate(true).open(&procedures_tmp_file)?;
            serde_json::to_writer(BufWriter::new(file), &procedures)?;
            std::fs::rename(procedures_tmp_file, &procedures_file)?;
            let metadata = std::fs::metadata(&procedures_file)?;
            opt_mtime = Some(FileTime::from_last_modification_time(&metadata));
        }
        lock.unlock()?;

        Ok((r, opt_mtime))
    }

    /// Add event to the current file
    fn add(&self, mut events: Vec<Event>) -> Result<(), Error> {
        for event in events.iter_mut() {
            match &mut event.payload {
                Payload::Command { text, .. }  => {
                    *text = text.trim().to_string();
                }
                _ => { }
            }
        }

        let lock = self.lock()?;
        let mut file = OpenOptions::new().create(true).append(true).open(self.main_db_file())?;
        for event in events.iter() {
            match &event.payload {
                Payload::Command { text, .. }  => {
                    if text == "" {
                        continue;
                    }
                }
                _ => { }
            }

            let string = format!("{}\n", serde_json::ser::to_string(&event)?);
            file.write(string.as_bytes())?;
        }
        lock.unlock()?;
        Ok(())
    }

    /// Somewhat behave like the 'fc' command for the full database
    fn fc(&self, workdir: &Option<String>, mut nr: u64, fetch: Option<u64>) -> Result<(), Error> {
        let full_timestamp = std::env::var("SUPERHIST_FC__FULL_TIMESTAMP").is_ok();

        let mut exits = std::collections::HashMap::new();
        type ExitMap = HashMap<(String, u64), (u32, UnixTime)>;
        let filter_func = |exits: &mut ExitMap, event: &Event| -> bool {
            match &event.payload {
                Payload::Command { workdir: command_workdir, .. } => {
                    if let Some(workdir) = workdir {
                        command_workdir == workdir
                    } else {
                        true
                    }
                }
                Payload::ExitCode(code) => {
                    exits.insert((event.terminal.clone(), event.idx), (*code, event.timestamp));
                    false
                }
                _ => {
                    false
                }
            }
        };

        let mut buffer = std::io::BufWriter::with_capacity(0x10000, std::io::stdout());
        let mut hashset = std::collections::HashSet::new();

        let mut print_func = |exits: &ExitMap, event: Event| -> Result<(), Error> {
            if let Payload::Command { text, .. } = event.payload {
                let key = (event.terminal.clone(), event.idx);
                if !hashset.contains(&text) {
                    let (print_nr, matching) = if let Some(fetch_nr) = fetch {
                        (false, fetch_nr == nr)
                    } else {
                        (true, true)
                    };
                    if matching {
                        if print_nr {
                            buffer.write(&format!("{} ", color::Fg(color::Rgb(60, 60, 60))).as_bytes())?;
                            buffer.write(&format!("{:width$}  ", nr, width=6).as_bytes())?;
                            use chrono::prelude::*;
                            let naive = NaiveDateTime::from_timestamp(event.timestamp as i64, 0);
                            let datetime: DateTime<Utc> = DateTime::from_utc(naive, Utc);
                            let converted: DateTime<Local> = DateTime::from(datetime);

                            use termion::color;
                            buffer.write(&format!("{}{} ",
                                    color::Fg(color::Rgb(100, 100, 100)),
                                    converted.format("%d.%m.%y")).as_bytes())?;

                            if full_timestamp {
                                buffer.write(&format!("{}{} ",
                                        color::Fg(color::Rgb(100, 100, 100)),
                                        converted.format("%H:%M:%S")).as_bytes())?;
                            }

                            if let Some((exitcode, _timestamp)) = exits.get(&key) {
                                if *exitcode == 0 {
                                    buffer.write(&format!("{}  ", color::Fg(color::Reset)).as_bytes())?;
                                } else {
                                    buffer.write(&format!("{}x{} ",
                                            color::Fg(color::Rgb(255, 0, 0)),
                                            color::Fg(color::Reset)).as_bytes())?;
                                }
                                buffer.write(&format!("{} ", color::Fg(color::Rgb(240, 240, 240))).as_bytes())?;
                            } else {
                                buffer.write(&format!("{}   ", color::Fg(color::Rgb(170, 170, 170))).as_bytes())?;
                            }
                            buffer.write(text.replace("\n", "\\n").as_bytes())?;
                        } else {
                            buffer.write(text.as_bytes())?;
                        }
                        buffer.write("\n".as_bytes())?;
                    }
                    hashset.insert(text);
                    nr += 1;
                }
            }
            Ok(())
        };

        let lock = self.lock()?;
        if self.main_db_file().exists() {
            let reader = BufReader::new(File::open(self.main_db_file())?);

            // Read current file
            let mut vx = vec![];
            for line in reader.lines() {
                vx.push(line?);
            }

            for line in vx.iter().rev() {
                let event : Event = serde_json::de::from_str(line)?;
                if filter_func(&mut exits, &event) {
                    print_func(&exits, event)?;
                }
            }

            lock.unlock()?;
        }

        // Read archive in reverse
        let archive = self.archive_dir();
        if archive.exists() {
            let mut v = vec![];
            for entry in std::fs::read_dir(&archive)? {
                v.push(entry?.path().to_owned());
            }
            v.sort();

            for path in v.iter().rev() {
                let s = path.to_string_lossy();
                if s.ends_with(".xz") {
                    let reader = BufReader::new(File::open(path)?);
                    let decompressor = BufReader::new(XzDecoder::new(reader));

                    for line in decompressor.lines() {
                        let event : Event = serde_json::de::from_str(line?.as_str())?;
                        if filter_func(&mut exits, &event) {
                            print_func(&exits, event)?;
                        }
                    }
                } else {
                    let reader = BufReader::new(File::open(path)?);
                    for line in reader.lines() {
                        let event : Event = serde_json::de::from_str(line?.as_str())?;
                        if filter_func(&mut exits, &event) {
                            print_func(&exits, event)?;
                        }
                    }
                }
            }
        }

        buffer.flush()?;

        Ok(())
    }
}

fn sub_main() -> Result<(), Error> {
    let opt = Opt::from_args();
    let superhist = SuperHist::new(opt.root);

    match opt.command {
        Command::Archive => {
            superhist.archive()?;
        },
        Command::Import { hist_file } => {
            superhist.import(&hist_file)?;
        },
        Command::FC { workdir, start_nr, fetch } => {
            superhist.fc(&workdir, start_nr, fetch)?;
        },
        Command::Add { timestamp, idx, terminal, command, workdir, exit_code, start } => {
            let event = Event {
                timestamp,
                idx,
                terminal,
                payload: match (command, workdir, exit_code, start) {
                    (Some(text), Some(workdir), None, false) => {
                        Payload::Command {
                            text,
                            workdir,
                        }
                    }
                    (None, None, Some(exit_code), false) => {
                        Payload::ExitCode(exit_code)
                    }
                    (None, None, None, true) => {
                        Payload::Start
                    }
                    _ => return Err(Error::InvalidParams),
                }
            };
            superhist.add(vec![event])?;
        },
        Command::ProcAdd { alias, command, workdir, interactive, prev_result } => {
            let mut superhist = superhist;
            if interactive {
                let prev_result = match prev_result {
                    None => None,
                    Some(x) => Some(serde_json::de::from_str(&x)?),
                };
                superhist.enter_proc_mode(ProcedureState::Add {
                    alias,
                    command,
                }, workdir, prev_result)?;
            } else {
                superhist.proc_add(alias, command, workdir)?;
            }
        }
        Command::ProcPick { workdir, prev_result } => {
            let prev_result = match prev_result {
                None => None,
                Some(x) => Some(serde_json::de::from_str(&x)?),
            };
            let mut superhist = superhist;
            superhist.enter_proc_mode(ProcedureState::Pick, workdir, prev_result)?;
        }
    }

    Ok(())
}

fn main() {
    match sub_main() {
        Ok(()) => {
            return;
        }
        Err(e) => {
            eprintln!("superhist: error - {}", e);
            std::process::exit(1);
        }
    }
}
