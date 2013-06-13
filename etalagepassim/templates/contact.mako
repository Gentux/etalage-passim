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
    <h2>${_('Contact')}</h2>
    <hr>
    <p>${_('''
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed laoreet commodo augue. In hac habitasse platea dictumst.
Ut lacinia orci posuere neque sodales cursus at sed lectus. Interdum et malesuada fames ac ante ipsum primis in
faucibus. Curabitur et risus posuere, venenatis felis id, cursus elit. Nam ut metus varius, varius tortor et, dignissim
ligula. Morbi tristique molestie lorem et dapibus. :
''')}
    </p>

    <ul>
        <li>${_('Lorem')}</li>
        <li>${_('ipsum')}</li>
        <li>${_('dolor')}</li>
        <li>${_('sit')}</li>
        <li>${_('amet')}</li>
    </ul>

    <h3>${_('Subheading 1')}</h3>
    <p>${_('''
Pellentesque tincidunt condimentum commodo. Donec luctus justo eu urna adipiscing pharetra. Nam malesuada, velit et
vulputate feugiat, libero turpis dignissim velit, id porttitor odio urna at metus. Nulla pharetra, eros sit amet
sollicitudin venenatis, massa ligula consectetur mauris, vel molestie nisi tellus nec dolor. Cras luctus eros sed
sollicitudin adipiscing. Praesent eu molestie odio, sit amet mollis massa. Maecenas ac fringilla ligula.
Nullam adipiscing quis justo eget ullamcorper. Phasellus congue ultrices ligula non facilisis. Maecenas luctus, enim
non ultrices semper, nibh leo tempus nisl, quis convallis enim augue vel justo. Nulla lacus lectus, malesuada ac
adipiscing sit amet, tincidunt id tellus. Integer eu nisl arcu. Phasellus dictum risus sed lectus molestie facilisis.
Aliquam luctus lacus commodo fermentum ornare. Vestibulum suscipit, sem eu adipiscing ultrices, massa odio feugiat
diam, vel aliquet sapien tellus sed quam. Aliquam pellentesque, massa sit amet ultricies pharetra, mauris sapien mattis
risus, et lobortis massa nisi id urna.
''')}
    </p>


    <h3>${_('Subheading 2')}</h3>
    <div class="row-fluid">
        <div class="span6">
            <h4>${_('Subheading')}</h4>
            <p>${_('Donec id elit non mi porta gravida at eget metus. Maecenas faucibus mollis interdum.')}</p>

            <h4>${_('Subheading')}</h4>
            <p>${_('Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Cras mattis consectetur purus sit amet fermentum.')}</p>

            <h4>${_('Subheading')}</h4>
            <p>${_('Maecenas sed diam eget risus varius blandit sit amet non magna.')}</p>
        </div>

        <div class="span6">
            <h4>${_('Subheading')}</h4>
            <p>${_('Donec id elit non mi porta gravida at eget metus. Maecenas faucibus mollis interdum.')}</p>

            <h4>${_('Subheading')}</h4>
            <p>${_('Morbi leo risus, porta ac consectetur ac, vestibulum at eros. Cras mattis consectetur purus sit amet fermentum.')}</p>

            <h4>${_('Subheading')}</h4>
            <p>${_('Maecenas sed diam eget risus varius blandit sit amet non magna.')}</p>
        </div>
    </div>


    <h3>${_('Subheading 3')}</h3>
    <p>${_('''
Fusce elementum eu est a laoreet. Sed sed magna nec elit gravida dictum ac id elit. Vestibulum ante ipsum primis in
faucibus orci luctus et ultrices posuere cubilia Curae; Vestibulum ac imperdiet orci, eget dictum augue. Quisque
condimentum justo rhoncus accumsan feugiat. Proin id ullamcorper felis, nec mollis urna. Morbi rhoncus a est quis
sagittis. Mauris bibendum tellus ipsum, rutrum vestibulum justo rutrum in. Aenean sagittis elit eget arcu porttitor
auctor. Sed gravida volutpat auctor. Aliquam erat volutpat. Nam ipsum nisi, lacinia ac sodales at, semper at orci. Duis
rhoncus congue libero, a mattis dui gravida in. Sed sodales at sapien a auctor. Quisque eleifend orci commodo nisl
interdum, sit amet vehicula odio gravida.
''')}
    </p>
</%def>
