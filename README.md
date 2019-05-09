# RT-Extension-Flock
Send webhook notifications to Flock (and many others) on various events in Request Tracker

## Introduction
This extension is designed for the packaged installation of Request Tracker 4 in Ubuntu 18.04 LTS to send webhook notifications to Flock. This extension is an improved version of and inspired by the Slack extension [found here](https://github.com/andrewwippler/RT-Extension-Slack).

### Request Tracker
Tested with and designed for RT version 4.4.2 that is shipped with Ubuntu 18.04 LTS. It should work with any installation of Request Tracker 4.

## Installation

### Requirements
    apt install request-tracker4 rt4-apache2 rt4-clients rt4-db-postgresql
    apt install make build-essential libmodule-install-perl

### Build the extension
    perl Makefile.PL
    make
    make install

You may need root permissions to do any of these steps

Edit `/etc/request-tracker4/RT_SiteConfig.pm` and install the extension by adding the folllowing line:

    Plugin('RT::Extension::Flock');

Clear your mason cache

    rm /var/cache/request-tracker4/mason_data/obj -fr
    mkdir /var/cache/request-tracker4/mason_data/obj
    chown www-data /var/cache/request-tracker4/mason_data/obj/

Restart your webserver

    service apache2 restart

## Configuration

This extension does not need any configuration. The webhook address is taken from the scrip so you can use many webhooks at the same time. This will give you a lot of flexibility in using this extension.

## Usage

1. Create a new `scrip`
1. Choose a description and condition, for example `On Create` to send a notification on newly created tickets
1. Action is `User Defined`
1. Template is `Blank`
1. Use the `Customer action preparation code` to trigger `Notify()` in the extension

You need to call `RT::Extension::Flock::Notify()` with exactly two arguments:

    message => {},
    address => https://api.flock.com/hooks/sendMessage/<uuid>

The `message` may contain multiple levels that will be converted to JSON before sending the webhook.

### Example code

```
# Get the ticket properties
my $ticket = $self->TicketObj;

# Construct the direct display link to this ticket
my $link = join RT->Config->Get('WebPort') == 443 ? 'https' : 'http','://',RT->Config->Get('WebDomain'),RT->Config->Get('WebPath'),'/Ticket/Display.html?id=',$ticket->Id;

# Get the name of the queue
my $queue = $ticket->QueueObj->Name;

# Get the name of the requestor, or use our name if we created the ticket
my $requestor = $ticket->RequestorAddresses || 'Request Tracker';

# Construct a message object to send to the webhook
my $message = {
 requestor => $requestor,
 subject => $ticket->Subject,
 ticket => {
  id => $ticket->Id,
  queue => $queue
 },
 link => $link
};

# Send the notification message to our webhook
RT::Extension::Flock::Notify(message => $message, address => 'https://api.flock.com/hooks/sendMessage/0260d544-1fa3-48c1-930e-00b9adaf81ac');
```

In Flock you can take arguments from the webhook and construct a nice message on one of your channels.

```
{"flockml":"New <strong>urgent</strong> incident [<strong>#$(json.ticket.id)</strong>] in queue [<strong>$(json.ticket.queue)</strong>] has been created<br/><a href=\"$(json.link)\">$(json.subject)</a>"}
```

In [Flock](https://flock.com/) you can create many webhooks, for different notifications (i.e. new ticket, ticket resolved) and different channels.

The webhook is plain JSON and will be sent with `application/json` Content-Type, therefore it should be compatible with many other webhooks, including Slack and Mattermost.
