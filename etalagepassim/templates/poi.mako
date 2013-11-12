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

from etalagepassim import conf, conv, model, ramdb, ramindexes, urls
%>\


<%inherit file="/site.mako"/>


<%def name="links()" filter="trim">
<link rel="canonical" href="${urls.get_full_url(ctx, 'organismes', poi.slug, poi._id)}">
</%def>


<%def name="container_content()" filter="trim">
<%
    fields = poi.generate_all_fields()
%>\
        <%self:poi_header fields="${fields}" poi="${poi}"/>
        <%self:poi_first_fields fields="${fields}" poi="${poi}"/>
        ##<%self:fields fields="${fields}" poi="${poi}"/>
</%def>


<%def name="css()" filter="trim">
    <%parent:css/>
    <link rel="stylesheet" href="${conf['leaflet.css']}">
<!--[if lte IE 8]>
    <link rel="stylesheet" href="${conf['leaflet.ie.css']}">
<![endif]-->
    <link rel="stylesheet" href="/css/map.css">
</%def>


<%def name="field(field)" filter="trim">
<%
    if field is None or field.value is None:
        return ''
%>\
        ${getattr(self, 'field_{0}'.format(field.id.replace('-', '_')), field_default)(field)}
</%def>


<%def name="field_adr(field)" filter="trim">
        <div class="field">
    % if strings.slugify(field.label) == u'adresse':
            <b class="field-label">${u'Adresse guichet' if field.type == 'geo' else u'Adresse postale' if field.type == 'postal' else u'Adresse'} :</b>
    % else:
            <b class="field-label">${field.label}${u' (guichet)' if field.type == 'geo' else u'  (adresse postale)' if field.type == 'postal' else u''} :</b>
    % endif
            <%self:field_value field="${field}"/>
        </div>
</%def>


<%def name="field_default(field)" filter="trim">
        <div class="field">
            <b class="field-label">${field.label} :</b>
            <%self:field_value field="${field}"/>
        </div>
</%def>


<%def name="field_link(field)" filter="trim">
<%
    if field.relation == 'parent':
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
        <%self:field field="${target_field}"/>
    % else:
        <div class="field">
            <b class="field-label">${field.label}</b>
            <ul class="unstyled">
        % for field in (target_fields or []):
            % if field.value is not None:
                <li><b>${field.label} :</b> <%self:field_value field="${field}"/></li>
            % endif
        % endfor
            </ul>
        </div>
    % endif
</%def>


<%def name="field_links(field)" filter="trim">
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
<%
        territories_id = set()
        transport_offers_infos = []
        for offer in targets:
            offer_territories_field = offer.get_first_field(u'territories', u'Territoire couvert')
            if offer_territories_field is not None:
                for territory_id in offer_territories_field.value:
                    territories_id.add(territory_id)

            offer_commercial_name_field = offer.get_first_field(u'name', u'Nom commercial')
            offer_commercial_name = offer_commercial_name_field.value \
                if offer_commercial_name_field is not None and offer_commercial_name_field.value is not None \
                else _(u'Name not known')
            offer_type_field = offer.get_first_field(u'select', u'Type de transport')
            offer_type = offer_type_field.value \
                if offer_type_field is not None and offer_type_field.value is not None \
                else _(u'Transpot type not known')
            offer_modes_field = offer.get_first_field(u'checkboxes', u'Mode de transport')
            offer_modes = u', '.join(mode for mode in offer_modes_field.value) \
                if offer_modes_field is not None and offer_modes_field.value is not None \
                else None

            transport_offers_infos.append((
                offer_commercial_name,
                offer_type,
                offer_modes,
                ))
        transport_offers_infos = sorted(
            transport_offers_infos,
            key = lambda transport_offer_infos: conf['transport_types_order'].index(
                strings.slugify(transport_offer_infos[1])
                ) if conf['transport_types_order'].count(strings.slugify(transport_offer_infos[1])) > 0
                else len(conf['transport_types_order']),
            )

        covered_territories_field = data['poi'].get_first_field(u'territories', u'Territoire couvert')
        territories = []
        if covered_territories_field is not None and covered_territories_field.value:
            territories = sorted(
                [
                    ramdb.territory_by_id[territory_id]
                    for territory_id in covered_territories_field.value
                    if ramdb.territory_by_id.get(territory_id)
                    ],
            key = lambda territory: getattr(territory, 'population', 0),
            )
        else:
            territories = sorted(
                [
                    ramdb.territory_by_id[territory_id]
                    for territory_id in territories_id
                    if ramdb.territory_by_id.get(territory_id)
                    ],
                key = lambda territory: getattr(territory, 'population', 0),
                )
%>\
        <div class="field">
            <b class="field-label">${_('Covered Territories')}</b>
            <p>${', '.join(territory.main_postal_distribution_str for territory in (territories or []))}</p>
        </div>
        <div class="field">
            <b class="field-label">${_('Transport Offers')}</b>
            <table class="table table-bordered table-condensed">
                <tr>
                    <th>${_('Name')}</th>
                    <th>${_('Transport Type')}</th>
                    <th>${_('Transport Mode')}</th>
                </tr>
        % for offer_commercial_name, offer_type, offer_modes in transport_offers_infos:
                <tr>
                    <td>${offer_commercial_name}</td>
                    <td>${offer_type}</td>
                    <td>${offer_modes}</td>
                </tr>
        % endfor
            </table>
        </div>
    % else:
        <div class="field">
            <b class="field-label">${field.label}</b>
        % if len(targets) == 1:
<%
            target = targets[0]
%>\
            <%self:fields fields="${target.generate_all_fields()}" poi="${target}"/>
        % else:
            <ul>
            % for target in targets:
                <li>
                   <%self:fields fields="${target.generate_all_fields()}" poi="${target}"/>
                </li>
            % endfor
            </ul>
        % endif
        </div>
    % endif
</%def>
<%def name="field_name(field)" filter="trim">
    % if depth > 0:
        <%self:field_default field="${field}"/>
    % endif
</%def>


<%def name="field_value(field)" filter="trim">
<%
    if field.value is None:
        return ''
%>\
    ${getattr(self, 'field_value_{0}'.format(field.id.replace('-', '_')), field_value_default)(field)}
</%def>


<%def name="field_value_adr(field)" filter="trim">
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


<%def name="field_value_autocompleter(field)" filter="trim">
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


<%def name="field_value_autocompleters(field)" filter="trim">
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


<%def name="field_value_boolean(field)" filter="trim">
            <span class="field-value">${u'Oui' if field.value and field.value != '0' else u'Non'}</span>
</%def>


<%def name="field_value_checkboxes(field)" filter="trim">
            <%self:field_value_autocompleters field="${field}"/>
</%def>


<%def name="field_value_date_range(field)" filter="trim">
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


<%def name="field_value_default(field)" filter="trim">
            <span class="field-value">${field.value}</span>
</%def>


<%def name="field_value_email(field)" filter="trim">
            <span class="field-value"><a href="mailto:${field.value}">${field.value}</a></span>
</%def>


<%def name="field_value_feed(field)" filter="trim">
<%
    try:
        feed = feedparser.parse(field.value)
    except:
        feed = None
%>\
            <div class="field-value">
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


<%def name="field_value_geo(field)" filter="trim">
            <div class="field-value">
                <div class="bigger-map-link">
                    ${_('See on a map with')}
                    <a href="${u'http://www.openstreetmap.org/?mlat={0}&mlon={1}&zoom=15&layers=M'.format(
                            field.value[0], field.value[1])}" rel="external">OpenStreetMap</a>
                </div>
            </div>
</%def>


<%def name="field_value_image(field)" filter="trim">
            <div class="field-value"><img alt="" src="${field.value}"></div>
</%def>


<%def name="field_value_link(field)" filter="trim">
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


<%def name="field_value_links(field)" filter="trim">
    % if len(field.value) == 1:
<%
        single_field = model.Field(id = 'link', value = field.value[0])
%>\
<%self:field_value field="${single_field}"/>
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


<%def name="field_value_organism_type(field)" filter="trim">
<%
    category_slug = ramdb.category_slug_by_pivot_code.get(field.value)
    category = ramdb.category_by_slug.get(category_slug) if category_slug is not None else None
    category_name = category.name if category is not None else field.value
%>\
            <span class="field-value">${category_name}</span>
</%def>


<%def name="field_value_select(field)" filter="trim">
            <%self:field_value_autocompleter field="${field}"/>
</%def>


<%def name="field_value_source(field)" filter="trim">
            <div class="field-value">
    % for subfield in field.value:
        <%self:field field="${subfield}"/>
    % endfor
            </div>
</%def>


<%def name="field_value_source_url(field)" filter="trim">
            <%self:field_value_url field="${field}"/>
</%def>


<%def name="field_value_tags(field)" filter="trim">
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


<%def name="field_value_territories(field)" filter="trim">
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


<%def name="field_value_text_block(field)" filter="trim">
    % if u'\n' in field.value:
            <div class="field-value">${markupsafe.Markup('<br>').join(field.value.split('\n'))}</div>
    % else:
            <span class="field-value">${field.value}</span>
    % endif
</%def>


<%def name="field_value_text_rich(field)" filter="trim">
            <div class="field-value">${field.value | n}</div>
</%def>


<%def name="field_value_url(field)" filter="trim">
            <a class="field-value" href="${field.value}" rel="external">${field.value}</a>
</%def>


<%def name="fields(poi, fields)" filter="trim">
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
         <%self:field field="${field}"/>
    % endfor
</%def>


<%def name="footer_actions()" filter="trim">
            <p class="pull-right contribute-text">
    % if conf['data_email'] is not None:
<%
        subject = _(u'Contribution to PASSIM : [{0}]').format(poi.name)
        body = _(u'''
Your are [an end-user, a company...]

Your e-mail address: [xxx@yyy.org]

Your contribution : [{0}]

Information Service {1}

- Info Service name
- Info booth:
- Call centre number :
- Web site address :
- Mobile site or application :
- Transport services covered:
   - Name, Territory (city, department, region), Transport type (public transport...):
- Your remarks (or information about web services, open data, real time info...):

Thank you advance for any remarks, questions or suggestions about PASSIM !
''').format(poi.name, poi.get_full_url(ctx))
%>
                <a class="label label-info" href="#input-modal">
                    ${_('Contribute')}
                </a>
                &mdash;
    % endif
    % if poi.petitpois_url is not None:
                <a href="${urlparse.urljoin(poi.petitpois_url, '/poi/view/{0}'.format(poi._id))}" \
rel="external">Accès back-office</a>
    % endif
            </p>
            <div class="hide fade modal" id="input-modal" role="dialog">
                <form class="form" action="/mail" method="GET">
                    <input name="callback-url" type="hidden" value="contact">
                    <fieldset>
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal" >×</button>
                            <h3>${_('Contact Form')}</h3>
                        </div>
                        <div class="modal-body">
                            <label><b>${_('Email')} :</b></label>
                            <input class="input-xxlarge"  id="email" name="email" type="text" \
placeholder="${_(u'Type your email…')}">

                            <label><b>${_('Subject')} :</b></label>
                            <input class="input-xxlarge" id="subject" name="subject" type="text" value="${subject}">

                            <label><b>${_('Body')} :</b></label>
                            <textarea id="body" name="body">${body}</textarea>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn" data-dismiss="modal">Cancel</button>
                            <button type="submit" class="btn btn-primary" value="send"/>Send</button>
                        </div>
                    </fieldset>
                </form>
            </div>
</%def>


<%def name="poi_first_fields(poi, fields)" filter="trim">
        <%self:field field="${model.pop_first_field(fields, 'last-update', u'Dernière mise à jour')}"/>
<%
site_web_link = model.pop_first_field(fields, 'link', u'Site web')
site_web_url = None
if site_web_link is not None and site_web_link.relation != 'parent':
    site_web_poi = model.Poi.instance_by_id.get(site_web_link.value)
    if site_web_poi is not None:
        for field in site_web_poi.generate_all_fields():
            if field.id == 'url':
                site_web_url = field.value
                break
%>
    % if site_web_url is not None:
        <div class="field">
            <b class="field-label">${_('Site web')} :</b>
            <a class="btn btn-primary btn-small internal" rel="tooltip" target="_blank" title="${_('Transport offer website.')}" \
href="${site_web_url}">${_('www')}</a>
        </div>
    % endif
<%
    mobile_applications_link = list(model.iter_fields(fields, 'link', u'Application mobile'))
%>
    % for mobile_application_link in mobile_applications_link:
<%
mobile_application_url_fields = None
if mobile_application_link is not None and mobile_application_link.relation != 'parent':
    mobile_application_poi = model.Poi.instance_by_id.get(mobile_application_link.value)
    mobile_application_fields = mobile_application_poi.generate_all_fields()
    mobile_application_url_fields = list(model.iter_fields(mobile_application_fields, 'url'))
    mobile_application_name = None
    if len(mobile_applications_link) > 1:
        for field in mobile_application_fields:
            if field.id == 'name':
                mobile_application_name = field.value
                break
%>
        % if mobile_application_url_fields is not None and len(mobile_application_url_fields) > 0:
        <div class="field">
            <b class="field-label">${_(u'Mobile applications')}\
${u' ({})'.format(mobile_application_name) if mobile_application_name is not None else u''} :</b>
            % for field in mobile_application_url_fields:
            <a class="btn btn-primary btn-small internal" rel="tooltip" target="_blank" title="${field.label}" \
href="${field.value}">${field.label}</a>
            % endfor
        </div>
        % endif
    % endfor
        <%self:field field="${model.pop_first_field(fields, 'links', u'Offres de transport')}"/>
<%
information_desk_link = model.pop_first_field(fields, 'link', u'Guichet d\'information')
if information_desk_link is not None and information_desk_link.relation != 'parent':
    information_desk_poi = model.Poi.instance_by_id.get(information_desk_link.value)
else:
    information_desk_poi = None
%>
    % if information_desk_poi is not None:
        <div class="field">
            <b class="field-label">${_('Information desk')} :</b>
        % for field in information_desk_poi.generate_all_fields():
            % if field.id in ['adr', 'geo', 'tel']:
            <%self:field field="${field}"/>
            % endif
        % endfor
        </div>
    % endif
<%
model.pop_first_field(fields, 'name', u'Nom du service')
open_data_field = model.pop_first_field(fields, 'link', u'Open data')
service_web_field = model.pop_first_field(fields, 'link', u'Service web')
%>
    % if open_data_field is not None or service_web_field is not None:
    <button type="button" class="btn btn-primary" data-toggle="collapse" data-target="#fields-toggle">
        <i class="icon-plus icon-white"></i> ${_("Other Available Services")}
    </button>
    <div id="fields-toggle" class="collapse">
        <%self:field field="${open_data_field}"/>
        <%self:field field="${service_web_field}"/>
    </div>
    % endif
</%def>


<%def name="poi_header(poi, fields)" filter="trim">
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
##    title_description = _('Multimodal information service') if poi.is_multimodal_info_service() \
##        else ramdb.schema_title_by_name[poi.schema_name]
    field = model.pop_first_field(fields, 'image', u'Logo')
%>\
            <h4>
                ${_(u'Detailed Sheet For')} \
<strong class="poi-name-label">${names[0]}</strong>${u' ({0})'.format(u', '.join(names[1:])) if names[1:] else u''}
    % if field is not None and field.value is not None:
                <img alt="" class="logo hidden-phone" src="${field.value}">
    % endif
            </h4>
        </div>
</%def>


<%def name="scripts()" filter="trim">
    <%parent:scripts/>
    <script src="${conf['leaflet.js']}"></script>
    <script src="/js/map.js"></script>
    <script>
var etalagepassim = etalagepassim || {};
etalagepassim.map.markersUrl = ${conf['images.markers.url'].rstrip('/') | n, js};
etalagepassim.map.tileLayersOptions = ${conf['tile_layers'] | n, js};
    </script>
</%def>


<%def name="scripts_domready_content()" filter="trim">
    <%parent:scripts_domready_content/>
    $(".contribute-text a").on("click", function() {
        $("#input-modal").modal("show");
    });
</%def>


<%def name="title_content()" filter="trim">
${parent.title_content()} - ${poi.name}
</%def>
