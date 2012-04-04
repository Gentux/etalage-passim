## -*- coding: utf-8 -*-


## Etalage -- Open Data POIs portal
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012 Easter-eggs
## http://gitorious.org/infos-pratiques/etalage
##
## This file is part of Etalage.
##
## Etalage is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%inherit file="/generic/site.mako"/>


<%def name="footer_service()" filter="trim">
            <p>
                Un service proposé par le CETE Méditerranée pour
                l’<a href="http://www.developpement-durable.gouv.fr/Presentation-de-l-AFIMB.html" rel="external">AFIMB</a>
                et la DGITM,
                réalisé par <a href="http://www.easter-eggs.com/" rel="external" title="Easter-eggs, société de services en logiciels libres">Easter-eggs</a>.
            </p>
</%def>


<%def name="site_header()" filter="trim">
    <div class="container-fluid">
        <div class="row-fluid">
            <img src="/passim-images/logo-ministere.png" style="float: left">
            <div class="page-header">
                <h1>
                    PASSIM-Plus
                </h1>
                <h2>
                    <small>Prototype 2012 en vue d’améliorer le
                        <br>
                        Portail annuaire des sites et des services sur la mobilité</small>
                </h2>
            </div>
        </div>
    </div>
</%def>


<%def name="topbar()" filter="trim">
    <div class="navbar navbar-fixed-top">
        <div class="navbar-inner">
            <div class="container-fluid">
                <a class="brand" href="http://etalage.passim.comarquage.fr/">PASSIM-Plus</a>
                <ul class="nav">
                    <li><a href="http://www.cete-mediterranee.fr/tt13/www/article.php3?id_article=316">À propos</a></li>
                    <li><a href="http://passim.comarquage.fr/site-statique/">Contenu du jour</a></li>
                </ul>
                <ul class="nav pull-right">
                    <li><a href="http://www.passim.info/">Site actuel PASSIM</a></li>
                </ul>
            </div>
        </div>
    </div>
</%def>

