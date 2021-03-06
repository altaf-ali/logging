##
## this program is free software: you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## this program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
## General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with the nens libraray.  If not, see
## <http://www.gnu.org/licenses/>.
##
## Copyright © 2011-2013 by Mario Frasca
##

Logger <- setRefClass("Logger",
                      fields=list(
                        name = "character",
                        handlers="list",
                        level="numeric"),
                      methods=list(
                        getParent = function() {
                          parts <- strsplit(name, '.', fixed=TRUE)[[1]] # split the name on the '.'
                          removed <- parts[-length(parts)] # except the last item
                          parentName <- paste(removed, collapse='.')
                          return(getLogger(parentName))
                        },

                        .logrecord = function(record) {
                          if (record$level >= level) {
                            for (handler in handlers) {
                              if (record$level >= with(handler, level)) {
                                action <- with(handler, action)
                                formatter <- with(handler, formatter)
                                action(formatter(record), handler, record)
                              }
                            }
                          }

                          if(name != '') {
                            parentLogger <- getParent()
                            parentLogger$.logrecord(record)
                          }
                          invisible(TRUE)
                        },

                        log = function(msglevel, msg, ...) {
                          if (msglevel < level) {
                            return(invisible(FALSE))
                          }
                          ## fine, we create the record and pass it to all handlers attached to the
                          ## loggers from here up to the root.
                          record <- list()

                          optargs <- list(...)
                          if (is.character(msg)) {
                            ## invoked as ("printf format", arguments_for_format)
                            if (length(optargs) > 0)
                              msg <- do.call("sprintf", c(msg, lapply(optargs, function(x) if(length(x)==1) x else paste(x, collapse=','))))
                          } else {
                            ## invoked as list of expressions
                            ## this assumes that the function the user calls is two levels up, e.g.:
                            ## loginfo -> .levellog -> logger$log
                            ## levellog -> .levellog -> logger$log
                            external.call <- sys.call(-2)
                            external.fn <- eval(external.call[[1]])
                            matched.call <- match.call(external.fn, external.call)
                            matched.call <- matched.call[-1]
                            matched.call.names <- names(matched.call)

                            ## We are interested only in the msg and ... parameters,
                            ## i.e. in msg and all parameters not explicitly declared
                            ## with the function
                            is.output.param <- matched.call.names == "msg" |
                              !(matched.call.names %in% c(setdiff(names(formals(external.fn)), "...")))

                            label <- lapply(matched.call[is.output.param], deparse)
                            msg <- sprintf("%s: %s", label, c(msg, optargs))
                          }

                          ## strip leading and trailing whitespace from the final message.
                          msg <- sub("[[:space:]]+$", '', msg)
                          # msg <- sub("^[[:space:]]+", '', msg)
                          record$msg <- msg

                          record$timestamp <- sprintf("%s", Sys.time())
                          record$logger <- name
                          record$level <- namedLevel(msglevel)
                          record$levelname <- names(which(loglevels == record$level)[1])
                          if(is.na(record$levelname))
                            record$levelname <- paste("NumericLevel(", msglevel, ")", sep='')
                          ## cascade action in private method.
                          .logrecord(record)
                        },

                        setLevel = function(newLevel) {
                          if(is.character(newLevel))
                            newLevel <- loglevels[newLevel]
                          else if(is.numeric(newLevel))
                            newLevel <- namedLevel(level)
                          else newLevel <- NA
                          level <<- newLevel
                        },

                        getLevel = function() level,

                        getHandler = function(handler) {
                          if(!is.character(handler))
                            handler <- deparse(substitute(handler))
                          handlers[[handler]]
                        },

                        removeHandler = function(handler) {
                          if(!is.character(handler))  # handler was passed as its action
                            handler <- deparse(substitute(handler))
                          handlers <<- handlers[!(names(handlers) == handler)]
                        },

                        addHandler = function(handler, ..., level=NULL, formatter=defaultFormat) {
                          log_level <- ifelse(is.null(level), getLevel(), level)
                          
                          handlerEnv <- new.env()
                          if(is.character(handler)){
                            ## first parameter is handler name
                            handlerName <- handler
                            ## and hopefully action is in the dots
                            params <- list(...)
                            if(!'action' %in% names(params) && is.null(names(params)[[1]]))
                              assign('action', params[[1]], handlerEnv)
                          } else {
                            ## first parameter is handler action, from which we extract the name
                            updateOptions.environment(handlerEnv, action=handler)
                            handlerName <- deparse(substitute(handler))
                          }
                          updateOptions.environment(handlerEnv, ...)
                          assign('level', namedLevel(log_level), handlerEnv)
                          assign('formatter', formatter, handlerEnv)
                          removeHandler(handlerName)
                          if(with(handlerEnv, action)(NA, handlerEnv, dry=TRUE) == TRUE) {
                            handlers[[handlerName]] <<- handlerEnv
                          }
                        },

                        finest = function(...) { log(loglevels["FINEST"], ...) },
                        finer = function(...) { log(loglevels["FINER"], ...) },
                        fine = function(...) { log(loglevels["FINE"], ...) },
                        debug = function(...) { log(loglevels["DEBUG"], ...) },
                        info = function(...) { log(loglevels["INFO"], ...) },
                        warn = function(...) { log(loglevels["WARN"], ...) },
                        warning = function(...) { warn(...) },
                        error = function(...) { log(loglevels["ERROR"], ...) }))
