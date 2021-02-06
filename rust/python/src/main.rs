use pyo3::prelude::*;

fn main() -> PyResult<()> {
    Python::with_gil(|py| {
        let sys = py.import("sys")?;
        let version: String = sys.get("version")?.extract()?;

        println!("Hello, from Python {}", version);
        Ok(())
    })
}
