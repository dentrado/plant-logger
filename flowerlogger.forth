str: "192.168.1.137" constant: IP
9091 constant: PORT
str: "/metrics/job/flowerlogger" constant: URL

512 buffer: line-buf
variable: socket

: 2dip ( x y quot -- x y ) swap { dip } dip ;
: tri* ( x y z p q r -- ) { { 2dip } dip dip } dip execute ;
: tri@ ( x y z q -- ) dup dup tri* ;

: connect ( -- ) PORT IP TCP netcon-connect socket ! ;
: dispose ( -- ) socket @ netcon-dispose ;

: write-str ( str -- ) socket @ swap netcon-write ;
: write-number ( n -- ) line-buf swap >str line-buf write-str ;
: write-lf ( -- ) str: "\n" write-str ;
: write-header ( -- )
   str: "PUT " URL str: " HTTP/1.1\r\n" { write-str } tri@
   str: "Host: " IP str: ":" { write-str } tri@
   PORT write-number
   str: "\r\n" write-str
   str: "Content-Length: 128" write-str \ hack
   str: "\r\n\r\n" write-str ;
: write-soil-humidity ( -- )
   str: "soil_humidity " write-str
   adc-read write-number write-lf ;
: write-temp-and-humidity ( -- )
   dht-measure
   { str: "temperature " write-str write-number write-lf }
   { str: "humidity " write-str write-number write-lf }
   bi* ;

: send-measurements ( -- )
   connect
   write-header write-soil-humidity write-temp-and-humidity
   dispose ;

: timed-pause ( -- neg-diff ) ms@ pause ms@ - ;
: pause-ms ( ms -- ) begin dup 0 > while timed-pause + repeat drop ;

: measure-loop ( task -- )
   activate
      begin  15000 pause-ms  send-measurements  again
   deactivate ;

0 task: measure-task

: measure-start ( -- ) multi measure-task measure-loop ;

repl-start
measure-start
