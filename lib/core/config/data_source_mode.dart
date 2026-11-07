/// Fixed at build time: [demo] reads the bundled catalogue and sends no API
/// requests, [live] talks to the backend and never falls back to demo.
enum DataSourceMode { demo, live }
