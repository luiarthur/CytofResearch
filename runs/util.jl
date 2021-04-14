"""
Equivalent to `aws s3 sync <from> <to> <tags>` in terminal.

# Example

```julia
s3sync(from="resultsdir", to="s3://my-bucket", tags=`--exclude '*.nfs'`)
```
"""
s3sync(; from, to, tags=``) = run(`aws s3 sync $(from) $(to) $(tags)`)
