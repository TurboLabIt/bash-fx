fxSshTestAccess()
{
  if [ -z "$1" ]; then
    fxCatastrophicError "fxSshTestAccess: you must provide user@server as an argument"
  fi
  
  fxTitle "🔭 Testing SSH access to ##$1##..."
  
  ssh -t $1 'echo -e "🔭 \e[1;32mAccess to ##$(hostname)## GRANTED\e[0m 🔭"'
  
  if [ "$?" != 0 ]; then
    fxCatastrophicError "Access to ##$1## DENIED"
  fi
}


fxSshCheckRemoteDirectory()
{
  if [ -z "$1" ] || [ -z "$2" ]; then
    fxCatastrophicError "fxSshTestRemoteDirectory: you must provide these arguments: user@server /path/to/test/"
  fi

  fxTitle "🔭 Checking if ##$2## exists on ##$1##..."
  
  ssh -t $1 "[ -d $2 ]"
  
  if [ "$?" != 0 ]; then
    fxCatastrophicError "##$2## doesn't exists on ##$1##"
  fi
  
  fxOK "Yes, ##$2## exists on ##$1##!"
  
  fxTitle "📂 Remote listing..."
  ssh -t $1 "ls -lah $2"
}
