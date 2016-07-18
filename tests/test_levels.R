library(logging)

LOG_FILE <- "/tmp/foo.log"
LOG_LEVEL <- "DEBUG"

logReset()
logger <- getLogger("root")
logger$setLevel(LOG_LEVEL)
logger$addHandler(writeToConsole)
logger$addHandler(writeToFile, file = LOG_FILE)

logger$info("Starting")
logger$debug("Doing something useful")
logger$debug('         Message with spaces')
logger$warning("Terminating-----------")


