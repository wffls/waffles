CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CUR_DIR/../init.sh"

log.info "string.split"
log.info "single-character"
unset x
x="foo.bar"
string.split "$x" "."
if [[ ${__split[0]} == "foo" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "multi-character test"
unset x
x="foo...bar"
string.split "$x" "..."
if [[ ${__split[1]} == "bar" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "string.trim"
unset x
x="  foo  "
x=$(string.trim "$x")
if [[ $x == "foo" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "array.length"
unset x
x=(foo bar baz bah)
length=$(array.length x)
if [[ $length == 4 ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "array.push"
unset x
x=(foo bar)
array.push x baz
if [[ ${x[2]} == "baz" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "array.pop"
unset x
unset y
x=(foo bar baz)
array.pop x y
if [[ ${x[1]} == "bar" ]] && [[ $y == "baz" ]]; then
  log.info OK
else
  log.error FAIL
fi

unset x
unset y
x=(foo bar baz)
array.pop x
if [[ ${x[1]} == "bar" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "array.shift"
unset x
unset y
x=(foo bar baz)
array.shift x y
if [[ ${x[0]} == "bar" ]] && [[ $y == "foo" ]]; then
  log.info OK
else
  log.error FAIL
fi

unset x
unset y
x=(foo bar baz)
array.shift x
if [[ ${x[0]} == "bar" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "array.unshift"
unset x
x=(bar baz)
array.unshift x "foo"
if [[ ${x[0]} == "foo" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "array.join"
unset x
unset y
x=(foo bar baz)
y=$(array.join x ",")
if [[ $y == "foo,bar,baz" ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "array.contains"
unset x
x=(foo bar baz)
array.contains x "bar"
if [[ $? == 0 ]]; then
  log.info OK
else
  log.error FAIL
fi

log.info "hash.keys"
unset x
unset y
declare -A x
x["foo"]=1
x["bar"]=2
x["baz"]=3
hash.keys x y
array.contains y "foo"
if [[ $? == 0 ]]; then
  log.info OK
else
  log.error FAIL
fi
