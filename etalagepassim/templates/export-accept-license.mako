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


<%!
from etalagepassim import model, urls
%>


<%inherit file="/site.mako"/>


<%def name="container_content()" filter="trim">
        <h2>${export_title}</h2>
        <div class="license">
            <img alt="${_(u"Open Licence Logo")}" class="thumbnail" src="http://a35.idata.over-blog.com/4/37/99/26/licence-ouverte-open-licence.gif" width="250">
            <p>
                Dans le cadre de la politique du Gouvernement en faveur de l’ouverture des données publiques
                (« Open Data »), Etalab a conçu la « Licence Ouverte / Open Licence ». Cette licence, élaborée en
                concertation avec l’ensemble des acteurs concernés, facilite et encourage la réutilisation des données
                publiques mises à disposition gratuitement.
            </p>
            <p>
                La « Licence Ouverte / Open Licence » présente les caractéristiques suivantes :
            </p>
            <ul>
                <li>
                    Une grande liberté de réutilisation des informations :
                    <ul>
                        <li>
                            Une licence ouverte, libre et gratuite, qui apporte la sécurité juridique nécessaire aux
                            producteurs et aux réutilisateurs des données publiques ;
                        </li>
                        <li>
                            Une licence qui promeut  la réutilisation la plus large en autorisant la reproduction,
                            la redistribution, l’adaptation et l’exploitation commerciale des données ;
                        </li>
                        <li>
                            Une licence qui s’inscrit dans un contexte international en étant compatible avec les
                            standards des licences Open Data développées à l’étranger et notamment celles du
                            gouvernement britannique (Open Government Licence) ainsi que les autres standards
                            internationaux (ODC-BY, CC-BY 2.0).
                        </li>
                    </ul>
                </li>
                <li>
                    Une exigence forte de transparence de la donnée et de qualité des sources en rendant obligatoire
                    la mention de la paternité.
                </li>
                <li>
                    Une opportunité de mutualisation pour les autres données publiques en mettant en place un
                    standard réutilisable par les collectivités territoriales qui souhaiteraient se lancer dans
                    l’ouverture des données publiques.
                </li>
            </ul>
            <p>
                Télécharger la « Licence Ouverte / Open Licence » :
            </p>
            <ul>
                <li>
                    Français :
                    <a href="http://ddata.over-blog.com/xxxyyy/4/37/99/26/licence/Licence-Ouverte-Open-Licence.pdf">PDF</a>
                    -
                    <a href="http://ddata.over-blog.com/xxxyyy/4/37/99/26/licence/Licence-Ouverte-Open-Licence.rtf">RTF</a>
                </li>
                <li>
                    Anglais :
                    <a href="http://ddata.over-blog.com/xxxyyy/4/37/99/26/licence/Licence-Ouverte-Open-Licence-ENG.pdf">PDF</a>
                    -
                    <a href="http://ddata.over-blog.com/xxxyyy/4/37/99/26/licence/Licence-Ouverte-Open-Licence-ENG.rtf">RTF</a>
                </li>
            </ul>
        </div>
        <form action="${urls.get_url(ctx, mode, type, format)}" class="form-horizontal" id="export-form" method="get">
            <fieldset>
    % for name, value in sorted(inputs.iteritems()):
<%
        name = model.Poi.rename_input_to_param(name)
        if name in (
                'accept',
                'submit',
                ):
            continue
        if value is None or value == u'':
            continue
%>\
        % if isinstance(value, list):
            % for item_value in value:
                    <input name="${name}" type="hidden" value="${item_value or ''}">
            % endfor
        % else:
                <input name="${name}" type="hidden" value="${value or ''}">
        % endif
    % endfor
<%
    error = errors.get('accept') if errors is not None else None
%>\
                <div class="control-group${' error' if error else ''}">
                    <label class="control-label" for="accept">${_(u"Accept License")}</label>
                    <div class="controls">
                        <label class="checkbox">
                            <input id="accept" name="accept" type="checkbox" value="1">
                            J'ai pris connaissance de la licence d'utilisation des données et j'en accepte les
                            conditions.
                        </label>
    % if error:
                        <p class="help-block">${error}</p>
    % endif
                    </div>
                </div>
                <div class="form-actions">
                    <button class="btn btn-primary" name="submit" type="submit" value="download"><i class="icon-download icon-white"></i> ${_('Download')}</button>
                </div>
            </fieldset>
        </form>
</%def>


<%def name="title_content()" filter="trim">
${export_title} - ${parent.title_content()}
</%def>

