function fxGetCpuArch()
{
  case "$(uname -m)" in
    x86_64) echo "amd64";;
    aarch64 | arm64) echo "arm64";;
  esac
}
