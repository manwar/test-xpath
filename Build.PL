use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'Test::XPath',
    license            => 'perl',
    configure_requires => { 'Module::Build' => '0.30', },
    build_requires     => {
        'Module::Build' => '0.30',
        'Test::More'    => '0.70',
    },
    requires => {
        'Test::Builder' => '0.70',
        'XML::LibXML'   => '1.69',
        'perl'          => 5.006002,
    },
    recommends => {
        'Test::Pod'           => '1.20',
        'Test::Pod::Coverage' => '1.06',
    },
    auto_features => {
        selectors => {
            description => 'CSS selectors support',
            requires    => { 'HTML::Selector::XPath' => '0.03', }
        }
    },
    meta_merge => {
        resources => {
            homepage   => 'http://search.cpan.org/dist/Test-XPath/',
            bugtracker => 'http://github.com/theory/test-xpath/issues/',
            repository => 'http://github.com/theory/test-xpath/tree/',
        }
    },
)->create_build_script;
