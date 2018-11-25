# Prometheus

Python library for querying Promethus and accessing data as a Pandas DataFrame.

This is mostly intended for use in a Jupyter notebook.

## Example

```
>>> import prometheus
>>>
>>> p = prometheus.Prometheus('http://raspberrypi.lan:9090')
>>> p.query('node_cpu{mode="system"}', '2018-11-23T00:00:00Z')
node_cpu{cpu="cpu2",instance="localhost:9100",job="node",mode="system"}    1041.01
node_cpu{cpu="cpu1",instance="localhost:9100",job="node",mode="system"}    1017.41
node_cpu{cpu="cpu3",instance="localhost:9100",job="node",mode="system"}    1002.68
node_cpu{cpu="cpu0",instance="localhost:9100",job="node",mode="system"}    1121.87
dtype: float64
```
