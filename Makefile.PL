use inc::Module::Install;

use Cwd;
use File::Copy;

use lib 'lib';
use OPUS::Tools;

name          'OPUS-Tools';
license       'gpl';
author        'Joerg Tiedemann';
include       'Module::AutoInstall';
version       '0.01';

install_script 'scripts/opusread';
install_script 'scripts/opus2moses';
install_script 'scripts/opus2multi';
install_script 'scripts/opusindex';

requires 'Cwd'             => 0;
requires 'Test::More'      => 0;
requires 'XML::Parser'     => 0;

auto_install;
WriteAll;
