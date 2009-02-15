use strict;
use inc::Module::Install;

name('Data-Localize');
all_from('lib/Data/Localize.pm');

requires 'Moose';
requires 'MooseX::AttributeHelpers';
requires 'Module::Pluggable::Object';
requires 'I18N::LangTags';

no_index directory => 't/lib';

auto_include_deps;

WriteAll;