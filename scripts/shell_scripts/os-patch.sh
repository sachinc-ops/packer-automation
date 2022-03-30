#/bin/bash
set -e

run_shell () {
    echo "Running OS Patching"
    sudo yum update -y -d1
}

skip_shell() {
    echo "Skipping OS Patching.."
}

[[ "$INPUT" == "run" ]] && run_shell || skip_shell
