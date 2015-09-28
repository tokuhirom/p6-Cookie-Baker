use v6;
unit class Cookie::Baker;

use URI::Encode;

sub bake_cookie(Str $name is copy, Str $value, Str :$domain, Str :$path, :$expires, Str :$max-age, Bool :$secure, Bool :$httponly, int :$time=time) is export {
    if $name ~~ /<-[a..z A..Z \- \. _ ~]>/ {
        $name = uri_encode($name);
    }

    my Str $cookie = "$name=" ~ uri_encode($value) ~ '; ';
    $cookie ~= "domain={$domain}; "                  if $domain.defined;
    $cookie ~= "path={$path}; "                      if $path.defined;
    $cookie ~= "expires={_date($expires, $time)}; "  if $expires.defined;
    $cookie ~= "max-age={$max-age}; "                if $max-age.defined;
    $cookie ~= 'secure; '                            if $secure;
    $cookie ~= 'HttpOnly; '                          if $httponly;
    $cookie = $cookie.substr(0, $cookie.chars-2); # remove trailing "; "
    $cookie;
}

my @WDAY = <Sun Mon Tue Wed Thu Fri Sat Sun>;
my @MON = <Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec>;

my %TERM = (
    's' => 1,
    'm' => 60,
    'h' => 3600,
    'd' => 86400,
    'M' => 86400 * 30,
    'y' => 86400 * 365,
);

my sub _date($expires, int $time) {
    my $expires_at;
    if ($expires ~~ /^\d+$/) {
        # all numbers -> epoch date
        $expires_at = $expires.Int;
    } elsif $expires ~~ /^ (<[-+]>?[\d+|\d*\.\d*])(<[smhdMy]>?)/ {
        my int $offset = (%TERM{$/[1].Str} || 1) * $/[0].Int;
        $expires_at = $time + $offset;
    } elsif ( $expires  eq 'now' ) {
        $expires_at = $time;
    } else {
        return $expires;
    }

    my $dt = DateTime.new($expires_at);
    # (cookies use '-' as date separator, HTTP uses ' ')
    return sprintf("%s, %02d-%s-%04d %02d:%02d:%02d GMT",
                   @WDAY[$dt.day-of-week], $dt.day-of-month, @MON[$dt.month-1], $dt.year,
                   $dt.hour, $dt.minute, $dt.second);
}

sub crush_cookie(Str $cookie_string) is export {
    return {} unless $cookie_string;

    my %results;
    my @pairs = grep /\=/, split /<[;,]>" "?/, $cookie_string;
    for @pairs ==> map { .trim } -> $pair {
        my ($key, $value) = split( "=", $pair, 2 );
        $key   = uri_decode($key);
        $value = uri_decode($value);

        # Take the first one like CGI.pm or rack do
        %results{$key} = $value unless %results{$key}:exists;
    }
    return %results;
}

=begin pod

=head1 NAME

Cookie::Baker - blah blah blah

=head1 SYNOPSIS

  use Cookie::Baker;

=head1 DESCRIPTION

Cookie::Baker is ...

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Tokuhiro Matsuno <tokuhirom@gmail.com>

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod
