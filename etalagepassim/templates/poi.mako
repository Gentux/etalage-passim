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
from etalage import model, ramdb
%>


<%inherit file="/generic/poi.mako"/>


<%def name="field_link(field, depth = 0)" filter="trim">
<%
    if field.relation == 'parent' and depth > 0:
        # Avoid infinite recursion.
        return u''
    target = ramdb.pois_by_id.get(field.value)
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
            ramdb.pois_by_id.get(target_id)
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
        offers_str = []
        for offer in targets:
            offer_fragments = []
            covered_territories_field = offer.get_first_field(u'territories', u'Territoire couvert')
            if covered_territories_field is not None and covered_territories_field.value is not None:
                offer_fragments.append(u', '.join(
                    territory.main_postal_distribution_str
                    for territory in (
                        ramdb.territories_by_id.get(territory_id)
                        for territory_id in covered_territories_field.value
                        )
                    if territory is not None
                    ))
            transport_type_field = offer.get_first_field(u'select', u'Type de transport')
            if transport_type_field is not None and transport_type_field.value is not None:
                if offer_fragments:
                    offer_fragments.append(u'/')
                offer_fragments.append(transport_type_field.value)
            transport_modes_field = offer.get_first_field(u'checkboxes', u'Mode de transport')
            if transport_modes_field is not None and transport_modes_field.value is not None:
                offer_fragments.append(u'({})'.format(u', '.join(mode for mode in transport_modes_field.value)))
            offers_str.append(u' '.join(offer_fragments))
%>\
        <div class="offset1">
        % if len(offers_str) == 1:
            ${offers_str[0]}
        % else:
            <ul>
            % for offer_str in offers_str:
                <li>${offer_str}</li>
            % endfor
        % endif
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
            <h2>${u', '.join(names)} <small>${ramdb.schemas_title_by_name[poi.schema_name]}</small></h2>
        </div>
<%
    field = model.pop_first_field(fields, 'image', u'Logo')
%>\
    % if field is not None and field.value is not None:
        <img alt="" class="logo" src="${field.value}" style="display: block;   margin-left: auto;   margin-right: auto">
    % endif
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

