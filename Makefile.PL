use inc::Module::Install;

use Cwd;
use File::Copy;

use lib 'lib';
use OPUS::Tools;

name          'OPUS-Tools';
license       'gpl';
author        'Joerg Tiedemann';
include       'Module::AutoInstall';
version       '0.03';

install_script 'scripts/opus-read';
install_script 'scripts/opus-index';
install_script 'scripts/opus-udpipe';
install_script 'scripts/opus2moses';
install_script 'scripts/opus2multi';

requires 'Cwd'             => 0;
requires 'Test::More'      => 0;
requires 'XML::Parser'     => 0;
requires 'XML::Writer'     => 0;
requires 'HTML::Entities'     => 0;

auto_install;
WriteAll;
