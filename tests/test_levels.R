#install.packages("~/Projects/logging", repos = NULL, type="source")

library(logging)

LOG_FILE <- "/tmp/foo.log"
LOG_LEVEL <- "DEBUG"

logReset()
logger <- getLogger("main")
logger$setLevel(LOG_LEVEL)
logger$addHandler(writeToConsole)
logger$addHandler(writeToFile, file = LOG_FILE)

logger$info("Starting")
logger$debug("Doing something useful")
logger$warning("Terminating-----------")

