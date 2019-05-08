use inc::Module::Install;

RTx     'RT-Extension-Flock';
license 'MIT';
repository 'https://github.com/MediaServe/RT-Extension-Flock';

requires_rt '4.0.0';
rt_too_new '4.4.4';

sign;
WriteAll;
