# == Class: dehydrated
#
# Include this class if you would like to create
# Certificates or on your puppetmaster to have you CSRs signed.
#
#
# === Parameters
#
# [*domains*]
#   Array of full qualified domain names (== commonname)
#   you want to request a certificate for.
#   For SAN certificates you need to pass space seperated strings,
#   for example ['foo.example.com fuzz.example.com', 'blub.example.com']
#
# [*dehydrated_git_url*]
#   URL used to checkout dehydrated using git.
#   Defaults to the upstream github url.
#
# [*channlengetype*]
#   Challenge type to use, default is 'dns-01'. Your dehydrated.sh
#   hook needs to be able to handle it.
#
# [*hook_source*]
#   Points to the source of the dehydrated.sh hook you'd like to
#   distribute ((as in file { ...: source => })
#   hook_source or hook_content needs to be specified.
#
# [*hook_content*]
#   The actual content (as in file { ...: content => }) of the
#   dehydrated hook.
#   hook_source or hook_content needs to be specified.
#
# [*dehydrated_host*]
#   The host you want to run dehydrated.sh on.
#   For now it needs to be a puppetmaster, as it needs direct access
#   to the certificates using functions in puppet.
#
# [*dehydrated_ca*]
#   The dehydrated CA you want to use. For debugging you want to
#   set it to 'https://acme-staging.api.letsencrypt.org/directory'
#
# [*dehydrated_contact_email*]
#   E-mail to use during the dehydrated account registration.
#   If undef, no email address is being used.
#
# [*dehydrated_proxy*]
#   Proxyserver to use to connect to the dehydrated CA
#   for example '127.0.0.1:3128'
#
# [*dh_param_size*]
#   dh parameter size, defaults to 2048
#
# [*manage_packages*]
#   install necessary packages, mainly git
#
# === Examples
#   class { 'dehydrated' :
#       domains     => [ 'foo.example.com', 'fuzz.example.com' ],
#       hook_source => 'puppet:///modules/mymodule/dehydrated_hook'
#   }
#
# === Authors
#
# Author Name Bernd Zeimetz <bernd@bzed.de>
#
# === Copyright
#
# Copyright 2016 Bernd Zeimetz
#
class dehydrated (
    $domains = [],
    $dehydrated_git_url = 'https://github.com/lukas2511/dehydrated.git',
    $challengetype = 'dns-01',
    $hook_source = undef,
    $hook_content = undef,
    $dehydrated_host = undef,
    $dehydrated_ca = 'https://acme-v01.api.letsencrypt.org/directory',
    $dehydrated_contact_email = undef,
    $dehydrated_proxy = undef,
    $dh_param_size = 2048,
    $manage_packages = true,
){

    require ::dehydrated::params
    require ::dehydrated::setup


    $dehydrated_real_host = pick(
        $dehydrated_host,
        $::servername,
        $::puppetmaster
    )

    if ($::fqdn == $dehydrated_real_host) {
        class { '::dehydrated::setup::puppetmaster' :
            manage_packages => $manage_packages,
        }

        if !($hook_source or $hook_content) {
            notify { '$hook_source or $hook_content needs to be specified!' :
                loglevel => err,
            }
        } else {
                dehydrated_git_url    => $dehydrated_git_url,
                dehydrated_ca            => $dehydrated_ca,
                hook_source               => $hook_source,
                hook_content              => $hook_content,
                dehydrated_contact_email => $dehydrated_contact_email,
                dehydrated_proxy         => $dehydrated_proxy,
            }
        }
        if ($::dehydrated_crts and $::dehydrated_crts != '') {
            $dehydrated_crts_array = split($::dehydrated_crts, ',')
            ::dehydrated::request::crt { $dehydrated_crts_array : }
        }
    }


    ::dehydrated::certificate { $domains :
        dehydrated_host => $dehydrated_real_host,
        challengetype    => $challengetype,
        dh_param_size    => $dh_param_size,
    }


}
