use structopt::StructOpt;
use std::path::PathBuf;
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

#[derive(Error, Debug)]
enum Error {
    #[error("I/O error; {0}")]
    IoError(#[from] std::io::Error),
    #[error("env var error; {0}")]
    VarError(#[from] std::env::VarError),
    #[error("json error; {0}")]
    CsvError(#[from] serde_json::Error),
    #[error("invalid parameters")]
    InvalidParams,
}

type UnixTime = u64;

#[derive(Debug, Deserialize, Serialize)]
pub enum Payload {
    Start,
    Command {
        text: String,
        workdir: String,
    },
    ExitCode(u32),
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

pub struct SuperHist {
    root: PathBuf,
}

impl SuperHist {
    fn new(path: PathBuf) -> Self {
        SuperHist {
            root: path
        }
    }

    fn lock_path(&self) -> PathBuf {
        self.root.join("lock")
    }

    fn current_file(&self) -> PathBuf {
        self.root.join("db.json")
    }

    fn archive_dir(&self) -> PathBuf {
        self.root.join("archive")
    }

    fn archive_file(&self)  -> Result<PathBuf, Error>  {
        use chrono::{Utc};
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
            let reader = BufReader::new(File::open(self.current_file())?);
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

        OpenOptions::new().write(true).truncate(true).open(self.current_file())?;

        std::fs::remove_file(self.current_file())?;

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
        let mut file = OpenOptions::new().create(true).append(true).open(self.current_file())?;
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
                            use termion::color;
                            buffer.write(&format!("{}{} ",
                                    color::Fg(color::Rgb(100, 100, 100)),
                                    datetime.format("%d.%m.%y")).as_bytes())?;

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
        let reader = BufReader::new(File::open(self.current_file())?);

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
                timestamp: timestamp,
                idx: idx,
                terminal: terminal,
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
