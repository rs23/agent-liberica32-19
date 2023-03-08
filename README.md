# agent-liberica32-19
Java agent to verify glitch in Bellsoft Liberica JDK 19 Linux 32-Bit

Tested running Bellsoft Liberica OpenJDK-Lite 19.0.2 Linux 32-Bit on Raspberry OS Desktop
(Linux raspberry 5.10.0-15-amd64 #1 SMP Debian 5.10.120-1 (2022-06-09))

Run the Bash script `run.sh`.
At the end, it starts the JVM without `--enable-preview` (succeeds)
and with `--enable-preview` (fails).
