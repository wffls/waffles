source ../lib/stdlib/system.sh

stdlib.info "stdlib.split"
stdlib.info "single-character"
unset x
x="foo.bar"
stdlib.split "$x" "."
if [[ ${__split[0]} == "foo" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "multi-character test"
unset x
x="foo...bar"
stdlib.split "$x" "..."
if [[ ${__split[1]} == "bar" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.trim"
unset x
x="  foo  "
x=$(stdlib.trim "$x")
if [[ $x == "foo" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.array_length"
unset x
x=(foo bar baz bah)
length=$(stdlib.array_length x)
if [[ $length == 4 ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.array_push"
unset x
x=(foo bar)
stdlib.array_push x baz
if [[ ${x[2]} == "baz" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.array_pop"
unset x
unset y
x=(foo bar baz)
stdlib.array_pop x y
if [[ ${x[1]} == "bar" ]] && [[ $y == "baz" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

unset x
unset y
x=(foo bar baz)
stdlib.array_pop x
if [[ ${x[1]} == "bar" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.array_shift"
unset x
unset y
x=(foo bar baz)
stdlib.array_shift x y
if [[ ${x[0]} == "bar" ]] && [[ $y == "foo" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

unset x
unset y
x=(foo bar baz)
stdlib.array_shift x
if [[ ${x[0]} == "bar" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.array_unshift"
unset x
x=(bar baz)
stdlib.array_unshift x "foo"
if [[ ${x[0]} == "foo" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.array_join"
unset x
unset y
x=(foo bar baz)
y=$(stdlib.array_join x ",")
if [[ $y == "foo,bar,baz" ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.array_contains"
unset x
x=(foo bar baz)
stdlib.array_contains x "bar"
if [[ $? == 0 ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi

stdlib.info "stdlib.hash_keys"
unset x
unset y
declare -A x
x["foo"]=1
x["bar"]=2
x["baz"]=3
stdlib.hash_keys x y
stdlib.array_contains y "foo"
if [[ $? == 0 ]]; then
  stdlib.info OK
else
  stdlib.error FAIL
fi
