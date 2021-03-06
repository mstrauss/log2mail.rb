log2mail.rb Installation
========================

Requirements
------------

* Linux
* Ruby 1.9.3

Debian 7 (and higher)
---------------------

To install Ruby:

    sudo apt-get install ruby

To get this pre-release version of log2mail.rb:

    rbenv shell system  # if using rbenv
    sudo gem install log2mail --pre

Next Steps
----------

Create a configuration file, e.g. at `/usr/local/etc/log2mail.conf`:

    cat > /usr/local/etc/log2mail.conf <<EOF
    defaults
      sendmail = /usr/sbin/sendmail
      mailto = your@mail.address
    file = /tmp/test.log
      pattern = test
    EOF

Test the configuration:

    log2mail.rb configtest --config /usr/local/etc/log2mail.conf

should return:

    +---------------+---------+-------------------+----------+
    | File          | Pattern | Recipient         | Settings |
    +---------------+---------+-------------------+----------+
    | /tmp/test.log | test    | your@mail.address |          |
    +---------------+---------+-------------------+----------+

Run *log2mail.rb* in foreground (`-N`) in verbose mode (`-v`) and 10 seconds sleep time in the processing loop:

    log2mail.rb start --config /usr/local/etc/log2mail.conf -Nv --sleeptime 10

`echo "a first test" >> /tmp/test.log` should result in an email report after few seconds.

See `gem man log2mail` for more information.
