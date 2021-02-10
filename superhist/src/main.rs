use structopt::StructOpt;
use std::path::PathBuf;
use std::io::Write;
use std::fs::{OpenOptions, File};
use std::io::{BufReader, BufRead};
use std::io::{BufWriter};
use thiserror::Error;
use regex::Regex;
use file_lock::FileLock;
use serde::{Serialize, Deserialize};
use xz2::read::{XzDecoder};
use xz2::write::{XzEncoder};

#[derive(Error, Debug)]
enum Error {
    #[error("I/O error; {0}")]
    IoError(#[from] std::io::Error),
    #[error("env var error; {0}")]
    VarError(#[from] std::env::VarError),
    #[error("json error; {0}")]
    CsvError(#[from] serde_json::Error),
    #[error("no storage path")]
    NoPathError,
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
    FC {
        #[structopt(short = "w")]
        workdir: Option<String>,

        #[structopt(short = "s")]
        start_nr: u64,
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
    root: Option<PathBuf>,

    #[structopt(subcommand)]
    command: Command,
}

lazy_static::lazy_static! {
    static ref RE: Regex = Regex::new(": ([0-9]+) (([^:]*):)?0;(.*)$").unwrap();
}

fn get_hist_root() -> Result<PathBuf, Error> {
    if let Ok(histfile) = std::env::var("HISTFILE") {
        if let Some(path) = PathBuf::from(histfile).parent() {
            return Ok(path.join("superhist"));
        }
    }

    Err(Error::NoPathError)
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

        lock.unlock()?;
        Ok(())
    }

    /// Add event to the current file
    fn add(&self, mut event: Event) -> Result<(), Error> {
        match &mut event.payload {
            Payload::Command { text, .. }  => {
                *text = text.trim().to_string();
                if text == "" {
                    return Ok(());
                }
            }
            _ => { }
        }
        let lock = self.lock()?;
        let mut file = OpenOptions::new().create(true).append(true).open(self.current_file())?;
        let string = format!("{}\n", serde_json::ser::to_string(&event)?);
        file.write(string.as_bytes())?;
        lock.unlock()?;
        Ok(())
    }

    /// Somewhat behave like the 'fc' command for the full database
    fn fc(&self, workdir: &Option<String>, mut nr: u64) -> Result<(), Error> {
        let filter_func = &|event: &Event| -> bool {
            if let Payload::Command { workdir: command_workdir, .. } = &event.payload {
                if let Some(workdir) = workdir {
                    command_workdir == workdir
                } else {
                    true
                }
            } else {
                false
            }
        };

        let mut buffer = std::io::BufWriter::with_capacity(0x10000, std::io::stdout());
        let mut hashset = std::collections::HashSet::new();
        let mut print_func = |event: Event| -> Result<(), Error> {
            if let Payload::Command { text, .. } = event.payload {
                if !hashset.contains(&text) {
                    buffer.write(&format!("{}  ", nr).as_bytes())?;
                    buffer.write(text
                        .replace("\\", "\\\\").replace("\n", "\\n").as_bytes())?;
                    buffer.write("\n".as_bytes())?;
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
            if filter_func(&event) {
                print_func(event)?;
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
                        if filter_func(&event) {
                            print_func(event)?;
                        }
                    }
                } else {
                    let reader = BufReader::new(File::open(path)?);
                    for line in reader.lines() {
                        let event : Event = serde_json::de::from_str(line?.as_str())?;
                        if filter_func(&event) {
                            print_func(event)?;
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
    let hist_root = get_hist_root()?;
    if !hist_root.exists() {
        std::fs::create_dir(&hist_root)?;
    }

    let superhist = SuperHist::new(hist_root);

    match opt.command {
        Command::Archive => {
            superhist.archive()?;
        },
        Command::FC { workdir, start_nr } => {
            superhist.fc(&workdir, start_nr)?;
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
            superhist.add(event)?;
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
