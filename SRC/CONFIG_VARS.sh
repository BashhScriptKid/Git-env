#------------------------------------------------------------------------------
# Global Variables
#------------------------------------------------------------------------------
# Configuration flags
DO_LOGGING=0
NO_SOURCING=1
INIT_CLEAR=0
PRINT_HEADER=1
NOT_GitDir=0
CHECK_UPDATES=1
# shellcheck disable=SC2034
readonly PROFESSIONAL_PERSONALITY=1

# Runtime variables
TARGET_PATH=""
GIT_PATH=${DEFAULT_GIT_PATH}
HISTFILE=""
LAST_DIR=""
ARG=""

