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


<%!
import urlparse

from biryani import strings

from etalage import conf, model, ramdb, urls
%>


<%inherit file="/generic/poi.mako"/>


<%def name="field_link(field, depth = 0)" filter="trim">
<%
    if field.relation == 'parent' and depth > 0:
        # Avoid infinite recursion.
        return u''
    target = model.Poi.instance_by_id.get(field.value)
    if target is None:
        return u''
    target_fields = target.generate_all_fields()
    if not target_fields:
        return u''
%>\
    % if len(target_fields) == 1:
<%
        target_field = target_fields[0]
        target_field_attributes = target_field.__dict__.copy()
        if target_field_attributes['id'] == 'name':
            target_field_attributes['id'] = 'text-inline'
        target_field_attributes['label'] = field.label
        target_field = model.Field(**target_field_attributes)
        print target_field
%>\
        <%self:field depth="${depth}" field="${target_field}"/>
    % else:
        <div class="page-header">
            <h3>${field.label}</h3>
        </div>
        <div class="offset1">
            <%self:fields depth="${depth + 1}" fields="${target_fields}" poi="${target}"/>
        </div>
    % endif
</%def>


<%def name="field_links(field, depth = 0)" filter="trim">
<%
    targets = [
        target
        for target in (
            model.Poi.instance_by_id.get(target_id)
            for target_id in field.value
            if target_id is not None
            )
        if target is not None
        ]
    if not targets:
        return u''
%>\
    % if field.label == u'Offres de transport':
        <div class="page-header">
            <h3>Couverture du service</h3>
        </div>
<%
        offers_infos_by_type_and_modes = {}
        for offer in targets:
            offer_territories_field = offer.get_first_field(u'territories', u'Territoire couvert')
            offer_territories_str = u', '.join(sorted(
                territory.main_postal_distribution_str
                for territory in (
                    ramdb.territory_by_id.get(territory_id)
                    for territory_id in offer_territories_field.value
                    )
                if territory is not None
                )) if offer_territories_field is not None and offer_territories_field.value is not None else None
            offer_type_field = offer.get_first_field(u'select', u'Type de transport')
            offer_type = offer_type_field.value \
                if offer_type_field is not None and offer_type_field.value is not None \
                else u'Type de transport non précisé'
            offer_modes_field = offer.get_first_field(u'checkboxes', u'Mode de transport')
            offer_modes = u', '.join(mode for mode in offer_modes_field.value) \
                if offer_modes_field is not None and offer_modes_field.value is not None \
                else None
            offer_commercial_name_field = offer.get_first_field(u'name', u'Nom commercial')
            offer_commercial_name = offer_commercial_name_field.value \
                if offer_commercial_name_field is not None and offer_commercial_name_field.value is not None \
                else None
            offers_infos_by_type_and_modes.setdefault((offer_type, offer_modes), []).append((
                offer_commercial_name,
                offer_territories_str,
                ))
%>\
        <div class="offset1">
            <ul>
        % for (offer_type, offer_modes), offers_infos in sorted(offers_infos_by_type_and_modes.iteritems()):
                <li><strong>${offer_type}</strong>
            % if offer_modes is not None:
                    (${offer_modes})
            % endif
                    <ul>
            % for offer_infos in sorted(offers_infos, key = lambda infos: (strings.slugify(infos[0]), infos[1])):
                        <li>${u' / '.join(
                                fragment
                                for fragment in offer_infos
                                if fragment is not None
                                )}</li>
            % endfor
                    </ul>
                </li>
        % endfor
            </ul>
        </div>
    % else:
        <div class="page-header">
            <h3>${field.label}</h3>
        </div>
        <div class="offset1">
        % if len(targets) == 1:
<%
            target = targets[0]
%>\
            <%self:fields depth="${depth + 1}" fields="${target.generate_all_fields()}" poi="${target}"/>
        % else:
            <ul>
            % for target in targets:
                <li>
                   <%self:fields depth="${depth + 1}" fields="${target.generate_all_fields()}" poi="${target}"/>
                </li>
            % endfor
            </ul>
        % endif
        </div>
    % endif
</%def>


<%def name="field_value_geo(field, depth = 0)" filter="trim">
            <div class="field-value">
    % if field.value[2] <= 6:
                <div class="alert alert-error">
                    Cet organisme est positionné <strong>très approximativement</strong>.
                </div>
    % elif field.value[2] <= 6:
                <div class="alert alert-warning">
                    Cet organisme est positionné <strong>approximativement dans la rue</strong>.
                </div>
    % endif
                <div class="single-marker-map" id="map-poi" style="height: 300px; width: 424px;"></div>
                <script>
etalage.map.singleMarkerMap("map-poi", ${field.value[0]}, ${field.value[1]});
                </script>
                <div class="bigger-map-link">
                    Voir sur une carte plus grande avec
                    <a href="${u'http://www.openstreetmap.org/?mlat={0}&mlon={1}&zoom=15&layers=M'.format(
                            field.value[0], field.value[1])}" rel="external">OpenStreetMap</a>
                    ou
                    <a href="${u'http://maps.google.com/maps?q={0},{1}'.format(field.value[0], field.value[1]
                            )}" rel="external">Google Maps</a>
                </div>
            </div>
</%def>


<%def name="footer_actions()" filter="trim">
            <p class="pull-right">
    % if conf['data_email'] is not None:
                <a class="label label-info" href="mailto:${u','.join(conf['data_email'])}?subject=${u'Correction fiche Passim+ : {name}'.format(
                        name = poi.name,
                        ).replace(u' ', u'%20')}&body=${u'''
Veuillez effectuer les modifications suivantes sur la fiche :
    {name}
{url}

Nom : ...
Couverture géographique : ....
Modes de transport : ....
Site web : ...
Application mobile : ...
Centre d'appel : ...
Guichet d'information : ...
OpenData : ...
Notes : ...
'''.format(
                        name = poi.name,
                        url = urls.get_full_url(ctx, 'organismes', poi._id),
                        ).strip().replace(u' ', u'%20').replace(u'\n', u'%0a')}">Modifier la fiche</a>
                &mdash;
    % endif
    % if conf.get('petitpois_url'):
                <a href="${urlparse.urljoin(conf['petitpois_url'], '/poi/view/{0}'.format(poi._id))}" rel="external">Accès back-office</a>
    % endif
            </p>
</%def>


<%def name="poi_header(poi, fields, depth = 0)" filter="trim">
        <div class="page-header">
<%
    names = [poi.name]
    alias_fields = list(
        field
        for field in model.iter_fields(fields, 'text-inline', label = u'Alias')
        )
    for field in alias_fields:
        if field.value is not None:
            names.append(field.value)
        fields.remove(field)
%>\
            <h2>
                ${u', '.join(names)} <small>${ramdb.schema_title_by_name[poi.schema_name]}</small>
<%
    field = model.pop_first_field(fields, 'image', u'Logo')
%>\
    % if field is not None and field.value is not None:
                <img alt="" class="logo" height="50" src="${field.value}">
    % endif
            </h2>
        </div>
        <%self:field depth="${depth}" field="${model.pop_first_field(fields, 'links', u'Offres de transport')}"/>
        <%self:field depth="${depth}" field="${model.pop_first_field(fields, 'link', u'Site web')}"/>
        <%self:field depth="${depth}" field="${model.pop_first_field(fields, 'link', u'Application mobile')}"/>
        <%self:field depth="${depth}" field="${model.pop_first_field(fields, 'link', u'''Centre d'appel''')}"/>
        <%self:field depth="${depth}" field="${model.pop_first_field(fields, 'link', u'''Guichet d'information''')}"/>
        <%self:field depth="${depth}" field="${model.pop_first_field(fields, 'link', u'Open data')}"/>
    % while True:
<%
        model.pop_first_field(fields, 'link', u'Opérateur')

        field = model.pop_first_field(fields, 'link')
        if field is None:
            break
%>\
        <%self:field depth="${depth}" field="${field}"/>
    % endwhile
    % while True:
<%
        field = model.pop_first_field(fields, 'links')
        if field is None:
            break
%>\
        <%self:field depth="${depth}" field="${field}"/>
    % endwhile
        <hr>
</%def>

