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
import urlparse

import feedparser
import markupsafe
from biryani import strings

from etalagepassim import conf, conv, model, ramdb, urls
%>\


<%inherit file="/site.mako"/>


<%def name="links()" filter="trim">
<link rel="canonical" href="${urls.get_full_url(ctx, 'organismes', poi.slug, poi._id)}">
</%def>


<%def name="container_content()" filter="trim">
<%
    fields = poi.generate_all_fields()

    accessibility_fields = []
    for field in fields[:]:
        if conv.check(conv.test_isinstance(basestring))(field.label) and field.label.endswith(u'[Accessibilité]'):
            field_attributes = field.__dict__.copy()
            field_attributes['label'] = field.label[:-len(u'[Accessibilité]')].rstrip()
            new_field = model.Field(**field_attributes)
            accessibility_fields.append(new_field)
            fields.remove(field)
    if accessibility_fields:
        theme_field_by_slug = {}
        for field in accessibility_fields[:]:
            try:
                theme, sub_label = field.label.split(u' - ', 1)
            except:
                theme  = u'Divers'
                sub_label = field.label
            else:
                theme = theme.rstrip()
            theme_slug = strings.slugify(theme)
            theme_field = theme_field_by_slug.get(theme_slug)
            if theme_field is None:
                theme_field_by_slug[theme_slug] = theme_field = model.Field(id = u'accessibility-theme', label = theme, value = [])
                accessibility_fields.insert(accessibility_fields.index(field), theme_field)
            field_attributes = field.__dict__.copy()
            field_attributes['label'] = sub_label.lstrip()
            theme_field.value.append(model.Field(**field_attributes))
            accessibility_fields.remove(field)
        accessibility_field = model.Field(id = u'accessibility', value = accessibility_fields)
        last_update_field = model.get_first_field(fields, 'last-update')
        if last_update_field is None:
            fields.append(accessibility_field)
        else:
            fields.insert(fields.index(last_update_field), accessibility_field)
%>\
        <%self:poi_header fields="${fields}" poi="${poi}"/>
        <%self:fields fields="${fields}" poi="${poi}"/>
</%def>


<%def name="css()" filter="trim">
    <%parent:css/>
    <link rel="stylesheet" href="${conf['leaflet.css']}">
<!--[if lte IE 8]>
    <link rel="stylesheet" href="${conf['leaflet.ie.css']}">
<![endif]-->
    <link rel="stylesheet" href="/css/map.css">
</%def>


<%def name="field(field, depth = 0)" filter="trim">
<%
    if field is None or field.value is None:
        return ''
%>\
        ${getattr(self, 'field_{0}'.format(field.id.replace('-', '_')), field_default)(field, depth = depth)}
</%def>


<%def name="field_accessibility(field, depth = 0)" filter="trim">
        <div>
            <p>
                <button class="btn btn-mini btn-primary btn-jaccede" data-toggle="collapse" data-target="#accessibilite">
                    Accessibilité
                    <i class="icon-plus-sign icon-white"> </i>
                </button>
                en partenariat avec
                <a href="http://www.jaccede.com/" rel="external"><img alt="Jaccede.com" src="/images/logo-jaccede-2.gif" style="height: 20px; vertical-align: text-bottom"></a>
            </p>
        </div>
        <div class="collapse in" id="accessibilite">
            <div class="well">
    % for sub_field in field.value:
            <%self:field depth="${depth + 1}" field="${sub_field}"/>
    % endfor
            </div>
        </div>
</%def>


<%def name="field_accessibility_theme(field, depth = 0)" filter="trim">
        <p class="jaccede-field-label"><strong>${field.label}</strong></p>
    % for sub_field in field.value:
        <%self:field depth="${depth + 1}" field="${sub_field}"/>
    % endfor
</%def>


<%def name="field_adr(field, depth = 0)" filter="trim">
        <div class="field">
    % if strings.slugify(field.label) == u'adresse':
            <b class="field-label">${u'Adresse guichet' if field.type == 'geo' else u'Adresse postale' if field.type == 'postal' else u'Adresse'} :</b>
    % else:
            <b class="field-label">${field.label}${u' (guichet)' if field.type == 'geo' else u'  (adresse postale)' if field.type == 'postal' else u''} :</b>
    % endif
            <%self:field_value depth="${depth}" field="${field}"/>
        </div>
</%def>


<%def name="field_default(field, depth = 0)" filter="trim">
        <div class="field">
            <b class="field-label">${field.label} :</b>
            <%self:field_value depth="${depth}" field="${field}"/>
        </div>
</%def>


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
<%def name="field_name(field, depth = 0)" filter="trim">
    % if depth > 0:
        <%self:field_default depth="${depth}" field="${field}"/>
    % endif
</%def>


<%def name="field_value(field, depth = 0)" filter="trim">
<%
    if field.value is None:
        return ''
%>\
    ${getattr(self, 'field_value_{0}'.format(field.id.replace('-', '_')), field_value_default)(field, depth = depth)}
</%def>


<%def name="field_value_adr(field, depth = 0)" filter="trim">
            <address class="field-value">
    % for subfield in field.value:
<%
        if subfield.value is None:
            continue
%>\
        % if subfield.id == 'street-address':
            % for line in subfield.value.split('\n'):
                ${line}<br>
            % endfor
        % elif subfield.id == 'commune':
<%
            continue
%>\
        % elif subfield.id == 'postal-distribution':
                ${subfield.value}
        % endif
    % endfor
            </address>
</%def>


<%def name="field_value_autocompleter(field, depth = 0)" filter="trim">
<%
    slug_and_name_couples = []
    name = field.value
    slug = strings.slugify(name)
    category = ramdb.category_by_slug.get(slug)
    if category is not None:
        name = category.name
%>\
            <span class="field-value">${name}</span>
</%def>


<%def name="field_value_autocompleters(field, depth = 0)" filter="trim">
<%
    slug_and_name_couples = []
    for name in field.value:
        slug = strings.slugify(name)
        category = ramdb.category_by_slug.get(slug)
        if category is not None:
            name = category.name
        slug_and_name_couples.append((slug, name))
    slug_and_name_couples.sort()
    names = [
        name
        for slug, name in slug_and_name_couples
        ]
%>\
            <span class="field-value">${u', '.join(names)}</span>
</%def>


<%def name="field_value_boolean(field, depth = 0)" filter="trim">
            <span class="field-value">${u'Oui' if field.value and field.value != '0' else u'Non'}</span>
</%def>


<%def name="field_value_checkboxes(field, depth = 0)" filter="trim">
            <%self:field_value_autocompleters depth="${depth}" field="${field}"/>
</%def>


<%def name="field_value_date_range(field, depth = 0)" filter="trim">
<%
    begin_field = field.get_first_field('date-range-begin')
    begin = begin_field.value if begin_field is not None else None
    end_field = field.get_first_field('date-range-end')
    end = end_field.value if end_field is not None else None
%>\
    % if begin is None:
            <span class="field-value">Jusqu'au ${end.strftime('%d/%m/%Y')}</span>
    % elif end is None:
            <span class="field-value">À partir du ${begin.strftime('%d/%m/%Y')}</span>
    % elif begin == end:
            <span class="field-value">Le ${begin.strftime('%d/%m/%Y')}</span>
    % else:
            <span class="field-value">Du ${begin.strftime('%d/%m/%Y')} au ${end.strftime('%d/%m/%Y')}</span>
    % endif
</%def>


<%def name="field_value_default(field, depth = 0)" filter="trim">
            <span class="field-value">${field.value}</span>
</%def>


<%def name="field_value_email(field, depth = 0)" filter="trim">
            <span class="field-value"><a href="mailto:${field.value}">${field.value}</a></span>
</%def>


<%def name="field_value_feed(field, depth = 0)" filter="trim">
<%
    try:
        feed = feedparser.parse(field.value)
    except:
        feed = None
%>\
            <div class="field-value offset1">
    % if feed is None or 'status' not in feed \
            or not feed.version and feed.status != 304 and feed.status != 401 \
            or feed.status >= 400:
                <em class="error">Erreur dans le flux d'actualité <a href="${field.value}" rel="external">${field.value}</a></em>
    % else:
                <strong>${feed.feed.title}</strong>
                <a href="${field.value}" rel="external"><img alt="" src="http://cdn.comarquage.fr/images/misc/feed.png"></a>
                <ul>
        % for entry in feed.entries[:10]:
                    <li class="feed-entry">${entry.title | n}
            % for content in (entry.get('content') or []):
                        <div>${content.value | n}</div>
            % endfor
                    </li>
        % endfor
        % if len(feed.entries) > 10:
                    <li>...</li>
        % endif
                </ul>
    % endif
            </div>
</%def>


<%def name="field_value_geo(field, depth = 0)" filter="trim">
            <div class="field-value">
    % if field.value[2] <= 6:
                <div class="alert alert-error">
                    Cet organisme est positionné <strong>très approximativement</strong>.
                </div>
    % elif field.value[2] <= 7:
                <div class="alert alert-warning">
                    Cet organisme est positionné <strong>approximativement dans la rue</strong>.
                </div>
    % endif
                <div class="single-marker-map" id="map-poi" style="height: 300px; width: 424px;"></div>
                <script>
etalagepassim.map.singleMarkerMap("map-poi", ${field.value[0]}, ${field.value[1]});
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


<%def name="field_value_image(field, depth = 0)" filter="trim">
            <div class="field-value"><img alt="" src="${field.value}"></div>
</%def>


<%def name="field_value_link(field, depth = 0)" filter="trim">
<%
    target = model.Poi.instance_by_id.get(field.value)
%>\
    % if target is None:
            <em class="field-value">Lien manquant</em>
    % else:
            <a class="field-value internal" href="${urls.get_url(ctx, 'organismes', target.slug, target._id
                    )}">${target.name}</a>
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
            target = model.Poi.instance_by_id.get(target_id)
            if target is None:
                continue
%>\
                <li><a class="internal" href="${urls.get_url(ctx, 'organismes', target.slug, target._id
                        )}">${target.name}</a></li>
        % endfor
            </ul>
    % endif
</%def>


<%def name="field_value_organism_type(field, depth = 0)" filter="trim">
<%
    category_slug = ramdb.category_slug_by_pivot_code.get(field.value)
    category = ramdb.category_by_slug.get(category_slug) if category_slug is not None else None
    category_name = category.name if category is not None else field.value
%>\
            <span class="field-value">${category_name}</span>
</%def>


<%def name="field_value_select(field, depth = 0)" filter="trim">
            <%self:field_value_autocompleter depth="${depth}" field="${field}"/>
</%def>


<%def name="field_value_source(field, depth = 0)" filter="trim">
            <div class="field-value offset1">
    % for subfield in field.value:
        <%self:field depth="${depth + 1}" field="${subfield}"/>
    % endfor
            </div>
</%def>


<%def name="field_value_source_url(field, depth = 0)" filter="trim">
            <%self:field_value_url depth="${depth}" field="${field}"/>
</%def>


<%def name="field_value_tags(field, depth = 0)" filter="trim">
<%
    tags_name = [
        tag.name
        for tag in (
            ramdb.category_by_slug.get(tag_slug)
            for tag_slug in sorted(field.value)
            )
        if tag is not None
        ]
%>\
            <span class="field-value">${u', '.join(tags_name)}</span>
</%def>


<%def name="field_value_territories(field, depth = 0)" filter="trim">
<%
    territories_title_markup = [
        territory.main_postal_distribution_str
            if territory.__class__.__name__ in model.communes_kinds
            else markupsafe.Markup(u'{0} <em>({1})</em>').format(
                territory.main_postal_distribution_str, territory.type_short_name_fr)
        for territory in (
            ramdb.territory_by_id[territory_id]
            for territory_id in field.value
            )
        if territory is not None
        ]
%>\
    % if territories_title_markup:
        % if len(territories_title_markup) == 1:
            <span class="field-value">${territories_title_markup[0] | n}</span>
        % else:
            <ul class="field-value">
            % for territory_title_markup in territories_title_markup:
                <li>${territory_title_markup | n}</li>
            % endfor
            </ul>
        % endif
    % endif
</%def>


<%def name="field_value_text_block(field, depth = 0)" filter="trim">
    % if u'\n' in field.value:
            <div class="field-value offset1">${markupsafe.Markup('<br>').join(field.value.split('\n'))}</div>
    % else:
            <span class="field-value">${field.value}</span>
    % endif
</%def>


<%def name="field_value_text_rich(field, depth = 0)" filter="trim">
            <div class="field-value offset1">${field.value | n}</div>
</%def>


<%def name="field_value_url(field, depth = 0)" filter="trim">
            <a class="field-value" href="${field.value}" rel="external">${field.value}</a>
</%def>


<%def name="fields(poi, fields, depth = 0)" filter="trim">
    % for field in (fields or []):
<%
        if conf['ignored_fields'] is not None and field.id in conf['ignored_fields']:
            ignored_field = conf['ignored_fields'][field.id]
            if ignored_field is None:
                # Always ignore a field with this ID>
                continue
            if strings.slugify(field.label) in ignored_field:
                # Ignore a field with this ID and this label
                continue
%>\
        <%self:field depth="${depth}" field="${field}"/>
    % endfor
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
    % if poi.petitpois_url is not None:
                <a href="${urlparse.urljoin(poi.petitpois_url, '/poi/view/{0}'.format(poi._id))
                        }" rel="external">Accès back-office</a>
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


<%def name="scripts()" filter="trim">
    <%parent:scripts/>
    <script src="${conf['leaflet.js']}"></script>
<!--[if lt IE 10]>
    <script src="${conf['pie.js']}"></script>
<![endif]-->
    <script src="/js/map.js"></script>
    <script>
var etalagepassim = etalagepassim || {};
etalagepassim.map.markersUrl = ${conf['images.markers.url'].rstrip('/') | n, js};
etalagepassim.map.tileLayersOptions = ${conf['tile_layers'] | n, js};
    </script>
</%def>


<%def name="scripts_domready_content()" filter="trim">
    <%parent:scripts_domready_content/>
    $(".collapse").collapse();
    $("button.btn-jaccede").on("click", function() {
        var $i = $(this).find("i");
        if ($i.hasClass("icon-plus-sign")) {
            $i.removeClass("icon-plus-sign");
            $i.addClass("icon-minus-sign");
        } else {
            $i.removeClass("icon-minus-sign");
            $i.addClass("icon-plus-sign");
        }
    });
    % if ctx.container_base_url is not None and ctx.gadget_id is not None:
    $('#accessibilite').on('hidden', function () {
        adjustFrameHeight(5);
    });
    $('#accessibilite').on('shown', function () {
        adjustFrameHeight(5);
    });
    % endif
</%def>


<%def name="title_content()" filter="trim">
${poi.name} - ${parent.title_content()}
</%def>
