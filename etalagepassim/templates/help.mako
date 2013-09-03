## -*- coding: utf-8 -*-


## Etalage-Passim -- Customization of Etalage for Passim
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012, 2013 Easter-eggs
## http://gitorious.org/passim/etalage-passim
##
## This file is part of Etalage-Passim.
##
## Etalage-Passim is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage-Passim is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%inherit file="/site.mako"/>


<%def name="container_content()" filter="trim">
    <h2>${_('Help')}</h2>
    <hr>

    <p>
        ${_(u'The PASSIM directory lists and describes the traveller information services in France, for all modes of \
transport.')}<br>
        ${_(u'The www.passim.info site works for fixed or mobile terminals on most web navigators, however if you have \
display problems, thank you for')} <a href="http://passim.mat.cst.easter-eggs.com/contact">${_('contacting us')}</a>.
    </p>

    <p>
        ${_(u'Please note that PASSIM does NOT provide directly transport information such as maps, schedules, or \
fares, ... but lists the relevant services which provide this detailed information.')}
    </p>

    <p>
        ${_(u'''You'd like to know the relevant Traveler Info Services for any place in France?''')}<br>
        ${_(u'Type in the place name (commune, département, région : the first letters typed will show a menu where \
you can select your choice) or, if you are located by your browser, click on the <GPS> button and you will obtain the \
list of relevant services known by PASSIM.')}<br>
        ${_(u'The list starts with Multimodal Info Services (i.e. services providing all info regarding Public \
Transport and alternatives to private car in a territory such as a Région or a Département) and then shows services of \
local, departmental, and regional interest, with indications of the transport type (urban - departmental - regional \
Public Transport, long distance transport, on-demand public transport, handicapped persons services, school services, \
bike sharing, car-sharing, ride-sharing, taxis, traffic and parking info, ports and airports...).')}<br>
        ${_(u'You can click on a particular service to see its detailed description and of course access directly to \
the web site for the service of interest.')}<br>
        ${_(u'On the right, there is a link towards the list of services covering the whole country (metropolitan \
France).')}
    </p>

    <p>
        ${_(u'You may also look for a particular information service name (if it is known, the name will appear in the \
menu list).')}
    </p>

    <p>
        ${_(u'If you think a service is incomplete, false or should be delete, please click on the <contribute> \
button on page bottom.')}<br>
        ${_(u'You are invited to')} <a href="http://passim.mat.cst.easter-eggs.com/contact">${_(u'ask any question or \
make any remark')}</a> ${_('or to')} <a href="http://passim.mat.cst.easter-eggs.com/contribute">${_('propose a new \
service to be included')}</a>.<br>
        ${_(u'Also, you are welcome to')} <a href="http://passim.mat.cst.easter-eggs.com/reuse">${_(u'reuse PASSIM \
content in your applications or services')}</a>.
    </p>

    <p>
        ${_(u'Thank you for using PASSIM and thank in advance for your comments!')}
    </p>
</%def>
