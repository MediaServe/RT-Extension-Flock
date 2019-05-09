use strict;
use warnings;
use HTTP::Request::Common qw(POST); 
use LWP::UserAgent; 
use JSON; 
package RT::Extension::Flock;

our $VERSION = '1.00';

=head1 NAME

RT-Extension-Flock - Send webhook notifications to Flock on various RT events

=head1 DESCRIPTION

This extension will make you able to send notifications to your Flock environment
using webhooks. It is using a JSON object for configuration that you can set in
real-time on triggering the extension.

=head1 RT VERSION

Works with RT 4.4.2

=head1 INSTALLATION

=over

=item C<perl Makefile.PL>

=item C<make>

=item C<make install>

May need root permissions

=item Edit F</etc/request-tracker4/RT_SiteConfig.pm>

Install the extension by adding the folllowing line:

    Plugin('RT::Extension::Flock');

=item Clear your mason cache

    rm /var/cache/request-tracker4/mason_data/obj -fr
    mkdir /var/cache/request-tracker4/mason_data/obj
    chown www-data /var/cache/request-tracker4/mason_data/obj/

=item Restart your webserver

    service apache2 restart

=back

=head1 AUTHOR

MediaServe International, Thomas Lobker E<lt>thomas@mediaserve.nlE<gt>

=head1 BUGS

All bugs should be reported on Github:

    L<github.com/MediaServe/RT-Extension-Flock/issues|https://github.com/MediaServe/RT-Extension-Flock/issues>

=head1 LICENSE AND COPYRIGHT

The MIT License (MIT)

Copyright (c) 2019 MediaServe International

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

sub Notify {
	my %args = @_;

	# Get the webhook address object from the payload

	my $address = $args{"address"};

	if (!$address) {
		$RT::Logger->error('Failed to push notification to Flock: no "address" specified in arguments');
		return;
	};

	# Get the message object from the payload

	if (!$args{"message"}) {
		$RT::Logger->error('Failed to push notification to Flock: no "message" hash specified in arguments');
		return;
	};

	# Recurse through the message hash and convert all hashes

	sub GetData {
		my $keys = $_[0];
		my $struct = {};

		foreach my $key (keys %{ $keys }) {
			my $value = $keys->{$key};
			if (ref $value eq ref {}) {
				$struct->{$key} = GetData($value);
			} else {
				$struct->{$key} = $value;
			};
		};

		return($struct);
	};

	my $message = GetData($args{"message"});
	my $data = JSON->new->utf8->encode($message);

	# Create the webhook

	my $request = HTTP::Request->new('POST', $address);
	$request->header('Content-Type' => 'application/json');
	$request->content($data);

	my $ua = LWP::UserAgent->new();
	$ua->timeout(10);

	RT::Logger->info('Pushing webhook notification to Flock: '.$data.' on address: '.$address);
	my $response = $ua->request($request);

	if ($response->is_success) {
		return;
	} else {
		$RT::Logger->error('Failed to push webhook notification ('.$response->code.': '.$response->message.')');
	};
};

1;
