
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  'build_requires' => {
    'Module::Build' => '0.3601'
  },
  'configure_requires' => {
    'Module::Build' => '0.3601'
  },
  'dist_abstract' => 'Drop-in replacement for sprintf(), with named parameter support',
  'dist_author' => [
    'Steven Haryanto <stevenharyanto@gmail.com>'
  ],
  'dist_name' => 'Text-sprintfn',
  'dist_version' => '0.04',
  'license' => 'perl',
  'module_name' => 'Text::sprintfn',
  'recommends' => {},
  'recursive_test_files' => 1,
  'requires' => {
    'Exporter::Lite' => '0',
    'Test::More' => '0.96',
    'perl' => '5.010000'
  },
  'script_files' => []
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;
