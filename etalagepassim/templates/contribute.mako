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
        ${_(u'PASSIM is frequently verified and completed but may still include errors. If you find any false or \
incomplete information, we thank you in advance for ')}<a href="http://passim.mat.cst.easter-eggs.com/contact">\
${_('contacting us')}</a>${_(' or ')}<a href="http://passim.mat.cst.easter-eggs.com/contribute">\
${_('contributing to improving the content')}</a>.
    </p>

    <p>
        ${_(u'You are welcome to contribute by submitting us :')}
    </p>

    <ul>
        <li>${_(u'A missing information')}</li>
        <li>${_(u'Any enhancement proposal')}</li>
        <li>${_(u'Any correction or complement for a particular service description page')}</li>
    </ul>

    <p>
        ${_(u'Thank you a lot ! Also, if you are interested in contributing more regularly, we may create an account \
for you on the back-office content management site.')}
    </p>
</%def>
