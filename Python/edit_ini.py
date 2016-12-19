
# http://stackoverflow.com/questions/11637467/modify-ini-file-with-python/11637494#11637494
# https://bigfix.me/relevance/details/3019050#comments

import ConfigParser
config=ConfigParser.RawConfigParser()
config.read(r'/tmp/gui.cfg')
config.set('gui','update_success_tray_report_enabled',r'yes')
with open(r'/tmp/gui.cfg', 'wb') as configfile:
    config.write(configfile)
