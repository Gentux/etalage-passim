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


<%def name="field_last_update(poi, depth = 0)" filter="trim">
</%def>


<%def name="field_value_link(field, depth = 0)" filter="trim">
<%
    target = ramdb.pois_by_id.get(field.value)
%>\
    % if target is None:
            <em class="field-value">Lien manquant</em>
    % else:
<%
        target_fields = target.fields[:] if target.fields is not None else None
        children = sorted(
            (
                child
                for child in ramdb.pois_by_id.itervalues()
                if child.parent_id == target._id
                ),
            key = lambda child: child.name,
            )
        for child in children:
            target_fields.append(model.Field(id = 'link', label = ramdb.schemas_title_by_name[child.schema_name],
                value = child._id))
%>\
            <div class="field-value offset1"><%self:fields depth="${depth + 1}" fields="${target_fields}" poi="${target}"/></div>
    % endif
</%def>


<%def name="field_value_links(field, depth = 0)" filter="trim">
    % if len(field.value) == 1:
<%
        single_field = model.Field(id = 'link', value = field.value[0])
%>\
<%self:field_value depth="${depth}" field="${single_field}"/>
    % else:
            <ul class="field-value">
        % for target_id in field.value:
<%
            target = ramdb.pois_by_id.get(target_id)
            if target is None:
                continue
            target_fields = target.fields[:] if target.fields is not None else None
            children = sorted(
                (
                    child
                    for child in ramdb.pois_by_id.itervalues()
                    if child.parent_id == target._id
                    ),
                key = lambda child: child.name,
                )
            for child in children:
                target_fields.append(model.Field(id = 'link', label = ramdb.schemas_title_by_name[child.schema_name],
                    value = child._id))
%>\
                <li>
                    <div class="field-value"><%self:fields depth="${depth + 1}" fields="${target_fields}" poi="${target}"/></div>
                </li>
        % endfor
            </ul>
    % endif
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
<%
    field = model.pop_first_field(fields, 'links', u'Offres de transport')
%>\
    % if field.value is not None:
        <div class="page-header">
            <h3>Couverture du service</h3>
        </div>
        <ul>
        % for offer_id in field.value:
<%
            offer = ramdb.pois_by_id.get(offer_id)
            if offer is None:
                continue
            covered_territories_field = offer.get_first_field(u'territories', u'Territoire couvert')
            transport_type_field = offer.get_first_field(u'select', u'Type de transport')
            transport_modes_field = offer.get_first_field(u'checkboxes', u'Mode de transport')
%>\
            <li>
            % if covered_territories_field is not None and covered_territories_field.value is not None:
                ${u', '.join(
                    territory.main_postal_distribution_str
                    for territory in (
                        ramdb.territories_by_id.get(territory_id)
                        for territory_id in covered_territories_field.value
                        )
                    if territory is not None
                    )}
                /
            % endif
            % if transport_type_field is not None and transport_type_field.value is not None:
                ${transport_type_field.value}
            % endif
            % if transport_modes_field is not None and transport_modes_field.value is not None:
                (${u', '.join(mode for mode in transport_modes_field.value)})
            % endif
            </li>
        % endfor
        </ul>
    % endif
<%
    values = []
    while True:
        field = model.pop_first_field(fields, 'link', u'Site web')
        if field is None:
            break
        if field.value is not None:
            values.append(field.value)
%>\
    % if values:
        <div class="page-header">
            <h3>Site web</h3>
        </div>
        <ul>
        % for web_site_id in values:
<%
            web_site = ramdb.pois_by_id.get(web_site_id)
            if web_site is None:
                continue
            url_field = web_site.get_first_field(u'url', u'URL')
            if url_field is None or url_field.value is None:
                continue
            infos_types_field = web_site.get_first_field(u'checkboxes', u"Types d'informations")
%>\
                <li>
                    <a href="${url_field.value}">${url_field.value}</a>
            % if infos_types_field is not None and infos_types_field.value is not None:
                    (${u', '.join(infos_types_field.value)})
            % endif
                </li>
        % endfor
        </ul>
    % endif
</%def>

