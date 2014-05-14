# -*- coding: utf-8 -*-


# Etalage-Passim -- Customization of Etalage for Passim
# By: Emmanuel Raviart <eraviart@easter-eggs.com>
#
# Copyright (C) 2011, 2012, 2013 Easter-eggs
# http://gitorious.org/passim/etalage-passim
#
# This file is part of Etalage-Passim.
#
# Etalage-Passim is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Etalage-Passim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""Controllers for territories"""


from cStringIO import StringIO
import datetime
import itertools
import logging
import smtplib
import zipfile

from biryani import strings

from . import conf, contexts, conv, model, pagers, ramdb, templates, urls, wsgihelpers


log = logging.getLogger(__name__)
N_ = lambda message: message


@wsgihelpers.wsgify
def about(req):
    ctx = contexts.Ctx(req)

    params = req.GET
    init_base(ctx, params)
    return templates.render(ctx, '/about.mako')


@wsgihelpers.wsgify
@ramdb.ramdb_based
def autocomplete_category(req):
    ctx = contexts.Ctx(req)

    headers = []
    params = req.GET
    inputs = dict(
        context = params.get('context'),
        jsonp = params.get('jsonp'),
        page = params.get('page'),
        tag = params.getall('tag'),
        term = params.get('term'),
        )
    data, errors = conv.pipe(
        conv.struct(
            dict(
                page = conv.pipe(
                    conv.input_to_int,
                    conv.test_greater_or_equal(1),
                    conv.default(1),
                    ),
                tag = conv.uniform_sequence(conv.input_to_tag_slug),
                term = conv.make_input_to_slug(separator = u' ', transform = strings.upper),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        conv.rename_item('page', 'page_number'),
        conv.rename_item('tag', 'tags_slug'),
        )(inputs, state = ctx)
    if errors is not None:
        return wsgihelpers.respond_json(
            ctx,
            dict(
                apiVersion = '1.0',
                context = inputs['context'],
                error = dict(
                    code = 400,  # Bad Request
                    errors = [
                        dict(
                            location = key,
                            message = error,
                            )
                        for key, error in sorted(errors.iteritems())
                        ],
                    # message will be automatically defined.
                    ),
                method = req.script_name,
                params = inputs,
                url = req.url.decode('utf-8'),
                ),
            headers = headers,
            jsonp = inputs['jsonp'],
            )

    possible_pois_id = ramdb.intersection_set(
        model.Poi.ids_by_category_slug[category_slug]
        for category_slug in (data['tags_slug'] or [])
        )
    if possible_pois_id is None:
        categories_infos = sorted(
            (-len(model.Poi.ids_by_category_slug.get(category_slug, [])), category_slug)
            for category_slug in ramdb.iter_categories_slug(tags_slug = data['tags_slug'], term = data['term'])
            if category_slug not in (data['tags_slug'] or [])
            )
    else:
        categories_infos = sorted(
            (-count, category_slug)
            for count, category_slug in (
                (
                    len(set(model.Poi.ids_by_category_slug.get(category_slug, [])).intersection(possible_pois_id)),
                    category_slug,
                    )
                for category_slug in ramdb.iter_categories_slug(tags_slug = data['tags_slug'], term = data['term'])
                if category_slug not in (data['tags_slug'] or [])
                )
            if count > 0 and count != len(possible_pois_id)
            )
    pager = pagers.Pager(item_count = len(categories_infos), page_number = data['page_number'])
    pager.items = [
        dict(
            count = -category_infos[0],
            tag = ramdb.category_by_slug[category_infos[1]].name,
            )
        for category_infos in categories_infos[pager.first_item_index:pager.last_item_number]
        ]
    return wsgihelpers.respond_json(
        ctx,
        dict(
            apiVersion = '1.0',
            context = inputs['context'],
            data = dict(
                currentItemCount = len(pager.items),
                items = pager.items,
                itemsPerPage = pager.page_size,
                pageIndex = pager.page_number,
                startIndex = pager.first_item_index,
                totalItems = pager.item_count,
                totalPages = pager.page_count,
                ),
            method = req.script_name,
            params = inputs,
            url = req.url.decode('utf-8'),
            ),
        headers = headers,
        jsonp = inputs['jsonp'],
        )


@wsgihelpers.wsgify
@ramdb.ramdb_based
def autocomplete_names(req):
    ctx = contexts.Ctx(req)

    headers = []
    params = req.GET
    inputs = dict(
        context = params.get('context'),
        jsonp = params.get('jsonp'),
        page = params.get('page'),
        term = params.get('term'),
        )
    data, errors = conv.pipe(
        conv.struct(
            dict(
                page = conv.pipe(
                    conv.input_to_int,
                    conv.test_greater_or_equal(1),
                    conv.default(1),
                    ),
                term = conv.make_input_to_slug(separator = u' '),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        conv.rename_item('page', 'page_number'),
        )(inputs, state = ctx)
    if errors is not None:
        return wsgihelpers.respond_json(
            ctx,
            dict(
                apiVersion = '1.0',
                context = inputs['context'],
                error = dict(
                    code = 400,  # Bad Request
                    errors = [
                        dict(
                            location = key,
                            message = error,
                            )
                        for key, error in sorted(errors.iteritems())
                        ],
                    # message will be automatically defined.
                    ),
                method = req.script_name,
                params = inputs,
                url = req.url.decode('utf-8'),
                ),
            headers = headers,
            jsonp = inputs['jsonp'],
            )

    possible_words = list([
        word_slug
        for word_slug in model.Poi.ids_by_word.iterkeys()
        if word_slug.startswith(data['term'])
        ]) or None
    if possible_words is None:
        possible_pois_id = model.Poi.indexed_ids
    else:
        possible_pois_id = ramdb.union_set(
            model.Poi.ids_by_word.get(word, set())
            for word in possible_words
            )

    pager = pagers.Pager(item_count = len(possible_pois_id), page_number = data['page_number'])
    pager.items = list(itertools.islice(
        [
            model.Poi.instance_by_id.get(poi_id).name
            for poi_id in possible_pois_id
            ],
        pager.first_item_index,
        pager.last_item_number,
        ))

    return wsgihelpers.respond_json(
        ctx,
        dict(
            apiVersion = '1.0',
            context = inputs['context'],
            data = dict(
                currentItemCount = len(pager.items),
                items = pager.items,
                itemsPerPage = pager.page_size,
                pageIndex = pager.page_number,
                startIndex = pager.first_item_index,
                totalItems = pager.item_count,
                totalPages = pager.page_count,
                ),
            method = req.script_name,
            params = inputs,
            url = req.url.decode('utf-8'),
            ),
        headers = headers,
        jsonp = inputs['jsonp'],
        )


@wsgihelpers.wsgify
@ramdb.ramdb_based
def csv(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))

    csv_bytes_by_name, errors = conv.pipe(
        conv.inputs_to_pois_csv_infos,
        conv.csv_infos_to_csv_bytes,
        )(inputs, state = ctx)
    if errors is not None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    if not csv_bytes_by_name:
        return wsgihelpers.no_content(ctx)
    if len(csv_bytes_by_name) == 1:
        csv_filename, csv_bytes = csv_bytes_by_name.items()[0]
        req.response.content_type = 'text/csv; charset=utf-8'
        req.response.content_disposition = 'attachment;filename={0}'.format(csv_filename)
        return csv_bytes
    zip_file = StringIO()
    with zipfile.ZipFile(zip_file, 'w') as zip_archive:
        for csv_filename, csv_bytes in csv_bytes_by_name.iteritems():
            zip_archive.writestr(csv_filename, csv_bytes)
    req.response.content_type = 'application/zip'
    req.response.content_disposition = 'attachment;filename=export.zip'
    return zip_file.getvalue()


@wsgihelpers.wsgify
@ramdb.ramdb_based
def excel(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))

    excel_bytes, errors = conv.pipe(
        conv.inputs_to_pois_csv_infos,
        conv.csv_infos_to_excel_bytes,
        )(inputs, state = ctx)
    if errors is not None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    if not excel_bytes:
        return wsgihelpers.no_content(ctx)
    req.response.content_type = 'application/vnd.ms-excel'
    req.response.content_disposition = 'attachment;filename=export.xls'
    return excel_bytes


@wsgihelpers.wsgify
@ramdb.ramdb_based
def export_directory_csv(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        accept = params.get('accept') or req.urlvars.get('accept'),
        submit = params.get('submit'),
        ))

    format = u'csv'
    mode = u'export'
    type = u'annuaire'

    accept, error = conv.pipe(conv.guess_bool, conv.default(False), conv.test_is(True))(inputs['accept'], state = ctx)
    if error is None:
        url_params = dict(
            (model.Poi.rename_input_to_param(input_name), value)
            for input_name, value in inputs.iteritems()
            )
        del url_params['accept']
        del url_params['submit']
        return wsgihelpers.redirect(
            ctx,
            location = urls.get_url(ctx, u'api/v1/{0}/{1}'.format(type, format), **url_params),
            )

    data, errors = conv.merge(
        model.Poi.make_inputs_to_search_data(),
        conv.struct(
            dict(
                accept = conv.test(
                    lambda value: not inputs['submit'],
                    error = N_(u"You must accept license to be allowed to download data."),
                    handle_none_value = True,
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = ctx)
    return templates.render(
        ctx,
        '/export-accept-license.mako',
        export_title = ctx._(u"Directory Export in CSV Format"),
        errors = errors,
        format = format,
        inputs = inputs,
        mode = mode,
        type = type,
        **model.Poi.extract_non_territorial_search_data(ctx, data))


@wsgihelpers.wsgify
@ramdb.ramdb_based
def export_directory_excel(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        accept = params.get('accept'),
        submit = params.get('submit'),
        ))

    format = u'excel'
    mode = u'export'
    type = u'annuaire'

    accept, error = conv.pipe(conv.guess_bool, conv.default(False), conv.test_is(True))(inputs['accept'], state = ctx)
    if error is None:
        url_params = dict(
            (model.Poi.rename_input_to_param(input_name), value)
            for input_name, value in inputs.iteritems()
            )
        del url_params['accept']
        del url_params['submit']
        return wsgihelpers.redirect(
            ctx,
            location = urls.get_url(ctx, u'api/v1/{0}/{1}'.format(type, format), **url_params),
            )

    data, errors = conv.merge(
        model.Poi.make_inputs_to_search_data(),
        conv.struct(
            dict(
                accept = conv.test(
                    lambda value: not inputs['submit'],
                    error = N_(u"You must accept license to be allowed to download data."),
                    handle_none_value = True,
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = ctx)
    return templates.render(
        ctx,
        '/export-accept-license.mako',
        export_title = ctx._(u"Directory Export in Excel Format"),
        errors = errors,
        format = format,
        inputs = inputs,
        mode = mode,
        type = type,
        **model.Poi.extract_non_territorial_search_data(ctx, data))


@wsgihelpers.wsgify
@ramdb.ramdb_based
def export_directory_geojson(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        accept = params.get('accept'),
        submit = params.get('submit'),
        ))

    format = u'geojson'
    mode = u'export'
    type = u'annuaire'

    accept, error = conv.pipe(conv.guess_bool, conv.default(False), conv.test_is(True))(inputs['accept'], state = ctx)
    if error is None:
        url_params = dict(
            (model.Poi.rename_input_to_param(input_name), value)
            for input_name, value in inputs.iteritems()
            )
        del url_params['accept']
        del url_params['submit']
        return wsgihelpers.redirect(
            ctx,
            location = urls.get_url(ctx, u'api/v1/{0}/{1}'.format(type, format), **url_params),
            )

    data, errors = conv.merge(
        model.Poi.make_inputs_to_search_data(),
        conv.struct(
            dict(
                accept = conv.test(
                    lambda value: not inputs['submit'],
                    error = N_(u"You must accept license to be allowed to download data."),
                    handle_none_value = True,
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = ctx)
    return templates.render(
        ctx,
        '/export-accept-license.mako',
        export_title = ctx._(u"Directory Export in GeoJSON Format"),
        errors = errors,
        format = format,
        inputs = inputs,
        mode = mode,
        type = type,
        **model.Poi.extract_non_territorial_search_data(ctx, data))


@wsgihelpers.wsgify
@ramdb.ramdb_based
def export_directory_kml(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        accept = params.get('accept'),
        submit = params.get('submit'),
        ))

    format = u'kml'
    mode = u'export'
    type = u'annuaire'

    accept, error = conv.pipe(conv.guess_bool, conv.default(False), conv.test_is(True))(inputs['accept'], state = ctx)
    if error is None:
        url_params = dict(
            (model.Poi.rename_input_to_param(input_name), value)
            for input_name, value in inputs.iteritems()
            )
        del url_params['accept']
        del url_params['submit']
        return wsgihelpers.redirect(
            ctx,
            location = urls.get_url(ctx, u'api/v1/{0}/{1}'.format(type, format), **url_params),
            )

    data, errors = conv.merge(
        model.Poi.make_inputs_to_search_data(),
        conv.struct(
            dict(
                accept = conv.test(
                    lambda value: not inputs['submit'],
                    error = N_(u"You must accept license to be allowed to download data."),
                    handle_none_value = True,
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = ctx)
    return templates.render(
        ctx,
        '/export-accept-license.mako',
        export_title = ctx._(u"Directory Export in KML Format"),
        errors = errors,
        format = format,
        inputs = inputs,
        mode = mode,
        type = type,
        **model.Poi.extract_non_territorial_search_data(ctx, data))


@wsgihelpers.wsgify
@ramdb.ramdb_based
def export_geographical_coverage_csv(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        accept = params.get('accept'),
        submit = params.get('submit'),
        ))

    format = u'csv'
    mode = u'export'
    type = u'couverture'

    accept, error = conv.pipe(conv.guess_bool, conv.default(False), conv.test_is(True))(inputs['accept'], state = ctx)
    if error is None:
        url_params = dict(
            (model.Poi.rename_input_to_param(input_name), value)
            for input_name, value in inputs.iteritems()
            )
        del url_params['accept']
        del url_params['submit']
        return wsgihelpers.redirect(
            ctx,
            location = urls.get_url(ctx, u'api/v1/{0}/{1}'.format(type, format), **url_params),
            )

    data, errors = conv.merge(
        model.Poi.make_inputs_to_search_data(),
        conv.struct(
            dict(
                accept = conv.test(
                    lambda value: not inputs['submit'],
                    error = N_(u"You must accept license to be allowed to download data."),
                    handle_none_value = True,
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = ctx)
    return templates.render(
        ctx,
        '/export-accept-license.mako',
        export_title = ctx._(u"Geographical Coverage Export in CSV Format"),
        errors = errors,
        format = format,
        inputs = inputs,
        mode = mode,
        type = type,
        **model.Poi.extract_non_territorial_search_data(ctx, data))


@wsgihelpers.wsgify
@ramdb.ramdb_based
def export_geographical_coverage_excel(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        accept = params.get('accept'),
        submit = params.get('submit'),
        ))

    format = u'excel'
    mode = u'export'
    type = u'couverture'

    accept, error = conv.pipe(conv.guess_bool, conv.default(False), conv.test_is(True))(inputs['accept'], state = ctx)
    if error is None:
        url_params = dict(
            (model.Poi.rename_input_to_param(input_name), value)
            for input_name, value in inputs.iteritems()
            )
        del url_params['accept']
        del url_params['submit']
        return wsgihelpers.redirect(
            ctx,
            location = urls.get_url(ctx, u'api/v1/{0}/{1}'.format(type, format), **url_params),
            )

    data, errors = conv.merge(
        model.Poi.make_inputs_to_search_data(),
        conv.struct(
            dict(
                accept = conv.test(
                    lambda value: not inputs['submit'],
                    error = N_(u"You must accept license to be allowed to download data."),
                    handle_none_value = True,
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = ctx)
    return templates.render(
        ctx,
        '/export-accept-license.mako',
        export_title = ctx._(u"Geographical Coverage Export in Excel Format"),
        errors = errors,
        format = format,
        inputs = inputs,
        mode = mode,
        type = type,
        **model.Poi.extract_non_territorial_search_data(ctx, data))


@wsgihelpers.wsgify
@ramdb.ramdb_based
def feed(req):
    ctx = contexts.Ctx(req)

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))

    data, errors = conv.inputs_to_atom_feed_data(inputs, state = ctx)
    non_territorial_search_data = model.Poi.extract_non_territorial_search_data(ctx, data)
    if errors is not None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    else:
        territory = data['geolocation'] or (data['term'] if not isinstance(data['term'], basestring) else None)
        pois_id_iter = model.Poi.iter_ids(
            ctx,
            territory = territory,
            **non_territorial_search_data)
        poi_by_id = dict(
            (poi._id, poi)
            for poi in (
                model.Poi.instance_by_id.get(poi_id)
                for poi_id in pois_id_iter
                )
            if poi is not None
            )
        pager = pagers.Pager(item_count = len(poi_by_id), page_number = 1)
        pager.items = sorted(
            poi_by_id.itervalues(),
            key = lambda poi: poi.last_update_datetime,
            reverse = True
            )
        data['feed_id'] = urls.get_full_url(ctx, **inputs)
        data['feed_url'] = data['feed_id']
        data['feed_updated'] = datetime.datetime.utcnow()
        data['author_name'] = ctx._(u'CEREMA')
        data['author_email'] = conf['data_email']

    req.response.content_type = 'application/atom+xml; charset=utf-8'
    return templates.render(
        ctx,
        '/feed-atom.mako',
        data = data,
        errors = errors,
        inputs = inputs,
        pager = pager,
        **non_territorial_search_data)


@wsgihelpers.wsgify
@ramdb.ramdb_based
def geographical_coverage_csv(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))

    csv_bytes_by_name, errors = conv.pipe(
        conv.inputs_to_geographical_coverage_csv_infos,
        conv.csv_infos_to_csv_bytes,
        )(inputs, state = ctx)
    if errors is not None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    if not csv_bytes_by_name:
        return wsgihelpers.no_content(ctx)
    if len(csv_bytes_by_name) == 1:
        csv_filename, csv_bytes = csv_bytes_by_name.items()[0]
        req.response.content_type = 'text/csv; charset=utf-8'
        req.response.content_disposition = 'attachment;filename={0}'.format(csv_filename)
        return csv_bytes
    zip_file = StringIO()
    with zipfile.ZipFile(zip_file, 'w') as zip_archive:
        for csv_filename, csv_bytes in csv_bytes_by_name.iteritems():
            zip_archive.writestr(csv_filename, csv_bytes)
    req.response.content_type = 'application/zip'
    req.response.content_disposition = 'attachment;filename=export.zip'
    return zip_file.getvalue()


@wsgihelpers.wsgify
@ramdb.ramdb_based
def geographical_coverage_excel(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))

    excel_bytes, errors = conv.pipe(
        conv.inputs_to_geographical_coverage_csv_infos,
        conv.csv_infos_to_excel_bytes,
        )(inputs, state = ctx)
    if errors is not None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    if not excel_bytes:
        raise wsgihelpers.no_content(ctx)
    req.response.content_type = 'application/vnd.ms-excel'
    req.response.content_disposition = 'attachment;filename=export.xls'
    return excel_bytes


@wsgihelpers.wsgify
@ramdb.ramdb_based
def index(req):
    ctx = contexts.Ctx(req)

    params = req.params
    init_base(ctx, params)

    default_tab = conf['default_tab'] \
        if ctx.container_base_url is None or ctx.gadget_id is None else conf['gadget_default_tab']
    # Redirect to another page.
    enabled_tabs = [
        tab_name
        for tab_key, tab_name in (
            (u'home', u'accueil'),
            (u'map', u'carte'),
            (u'list', u'liste'),
            (u'directory', u'annuaire'),
            (u'gadget', u'partage'),
            (u'export', u'export'),
            )
        if not getattr(ctx, "hide_{0}".format(tab_key))
        ]
    if not len(enabled_tabs):
        enabled_tabs = [u'carte']  # Ensure there is at least one visible tab
    url_args = (default_tab if default_tab in enabled_tabs else enabled_tabs[0],)
    url_kwargs = dict(params)
    if ctx.container_base_url is None or ctx.gadget_id is None:
        raise wsgihelpers.redirect(ctx, location = urls.get_url(ctx, *url_args, **url_kwargs))
    else:
        return templates.render(
            ctx,
            '/http-simulated-redirect.mako',
            url_args = url_args,
            url_kwargs = url_kwargs,
            )


@wsgihelpers.wsgify
@ramdb.ramdb_based
def index_export(req):
    ctx = contexts.Ctx(req)

    if conf['hide_export']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Export disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        submit = params.get('submit'),
        type_and_format = params.get('type_and_format'),
        ))
    mode = u'export'

    data, errors = conv.merge(
        model.Poi.make_inputs_to_search_data(),
        conv.struct(
            dict(
                type_and_format = conv.pipe(
                    conv.input_to_slug,
                    conv.test_in([
                        'annuaire-csv',
                        'annuaire-excel',
                        'annuaire-geojson',
                        'annuaire-kml',
                        'couverture-csv',
                        'couverture-excel',
                        ]),
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = ctx)
    if errors is None:
        if inputs['submit']:
            if data['type_and_format'] is not None:
                type, format = data['type_and_format'].rsplit(u'-', 1)

                # Form submitted. Redirect to another page.
                url_args = ('export', type, format)
                search_params_name = model.Poi.get_search_params_name(ctx)
                url_kwargs = dict(
                    (param_name, value)
                    for param_name, value in (
                        (model.Poi.rename_input_to_param(input_name), value)
                        for input_name, value in inputs.iteritems()
                        )
                    if param_name in search_params_name
                    )
                if ctx.container_base_url is None or ctx.gadget_id is None:
                    raise wsgihelpers.redirect(ctx, location = urls.get_url(ctx, *url_args, **url_kwargs))
                else:
                    return templates.render(
                        ctx,
                        '/http-simulated-redirect.mako',
                        url_args = url_args,
                        url_kwargs = url_kwargs,
                        )
            errors = dict(
                type_and_format = ctx._(u'Missing value'),
                )
    return templates.render(
        ctx,
        '/export.mako',
        errors = errors,
        inputs = inputs,
        mode = mode,
        **model.Poi.extract_non_territorial_search_data(ctx, data))


@wsgihelpers.wsgify
@ramdb.ramdb_based
def index_gadget(req):
    ctx = contexts.Ctx(req)

    if conf['hide_gadget']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Gadget page disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    mode = u'gadget'

    data, errors = conv.inputs_to_pois_list_data(inputs, state = ctx)

    return templates.render(
        ctx,
        '/gadget.mako',
        data = data,
        errors = errors,
        inputs = inputs,
        mode = mode,
        **data)


@wsgihelpers.wsgify
@ramdb.ramdb_based
def index_home(req):
    ctx = contexts.Ctx(req)

    if conf['hide_home']:
        return wsgihelpers.not_found(ctx, explanation = ctx._(u'Home page disabled by configuration'))

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    mode = u'home'

    data, errors = model.Poi.make_inputs_to_search_data()(inputs, state = ctx)
    non_territorial_search_data = model.Poi.extract_non_territorial_search_data(ctx, data)
    if errors is not None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    else:
        pois_id_iter = model.Poi.iter_ids(ctx, **non_territorial_search_data)
        poi_by_id = dict(
            (poi._id, poi)
            for poi in (
                model.Poi.instance_by_id.get(poi_id)
                for poi_id in pois_id_iter
                )
            if poi is not None
            )
        pager = pagers.Pager(
            item_count = len(poi_by_id),
            page_number = 1,
            page_max_size = 10,
            )
        pager.items = sorted(
            poi_by_id.itervalues(),
            key = lambda poi: poi.last_update_datetime,
            reverse = True
            )

    return templates.render(
        ctx,
        '/home.mako',
        data = data,
        errors = errors,
        inputs = inputs,
        mode = mode,
        pager = pager,
        **non_territorial_search_data)


@wsgihelpers.wsgify
@ramdb.ramdb_based
def index_list(req):
    ctx = contexts.Ctx(req)

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        coverage = params.get('coverage'),
        page = params.get('page'),
        poi_index = params.get('poi_index'),
        sort_key = params.get('sort_key'),
        ))
    mode = u'liste'

    data, errors = conv.inputs_to_pois_list_data(inputs, state = ctx)
    non_territorial_search_data = model.Poi.extract_non_territorial_search_data(ctx, data)
    if errors is not None:
        raise wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))

    territory = data['geolocation'] or (data['term'] if not isinstance(data['term'], basestring) else None)
    if non_territorial_search_data.get('term') and not isinstance(non_territorial_search_data['term'], basestring):
        non_territorial_search_data['term'] = None

    pois_id_iter = model.Poi.iter_ids(
        ctx,
        territory = territory,
        coverages = None if data['coverage'] is None else [data['coverage']],
        **non_territorial_search_data)

    if isinstance(data['term'], basestring):
        for poi_id in pois_id_iter:
            poi = model.Poi.instance_by_id[poi_id]
            if data['term'] == poi.slug:
                raise wsgihelpers.redirect(ctx, location = urls.get_url(ctx, 'organismes', poi.slug, poi._id))

    ids_by_territory_id = dict()
    multimodal_info_services_by_id = dict()
    national_territory_id = ramdb.territory_id_by_kind_code[('Country', 'FR')]
    ids_by_niveau = dict()
    transport_types_by_id = dict()
    web_site_by_id = dict()

    for poi in (
            model.Poi.instance_by_id.get(poi_id)
            for poi_id in pois_id_iter
            ):
        if poi is None:
            continue

        for field in poi.generate_all_fields():
            if poi._id in model.Poi.multimodal_info_service_ids:
                multimodal_info_services_by_id[poi._id] = poi
            else:
                if field.id == 'links' and strings.slugify(field.label) == 'offres-de-transport':
                    for transport_offer in [
                            transport_offer
                            for transport_offer in (
                                model.Poi.instance_by_id.get(transport_offer_id)
                                for transport_offer_id in field.value
                                )
                            if transport_offer is not None
                            ]:
                        for field in transport_offer.fields:
                            field_slug = strings.slugify(field.label)
                            if field_slug == 'type-de-transport' and field.value is not None:
                                transport_types_by_id.setdefault(poi._id, set()).add(field.value)

                if field.id == 'territories' and strings.slugify(field.label) == 'territoire-couvert':
                    for territory_id in field.value:
                        if isinstance(data['term'], model.Territory) and territory_id in data['term'].ancestors_id:
                            territory = ramdb.territory_by_id[territory_id]
                            if territory.__class__.__name__ != 'UrbanTransportsPerimeterOfFrance':
                                ids_by_territory_id.setdefault(territory_id, set()).add(poi._id)
                                break
                            else:
                                PTU_postal_routing = territory.main_postal_distribution.get('postal_routing')
                                if PTU_postal_routing is not None:
                                    for child_territory_id in ramdb.territories_id_by_ancestor_id.get(territory_id):
                                        child_territory = ramdb.territory_by_id.get(child_territory_id)
                                        if child_territory.__class__.__name__ != 'CommuneOfFrance':
                                            continue
                                        child_territory_postal_routing = child_territory.main_postal_distribution.get(
                                            'postal_routing'
                                            )
                                        if all(map(
                                                lambda word: word in child_territory_postal_routing.split(),
                                                PTU_postal_routing.split(),
                                                )):
                                            ids_by_territory_id.setdefault(child_territory_id, set()).add(poi._id)
                                            break
                    else:
                        ids_by_territory_id.setdefault(national_territory_id, set()).add(poi._id)

                if field.id == 'select' and strings.slugify(field.label) == 'niveau':
                    ids_by_niveau.setdefault(strings.slugify(field.value), set()).add(poi._id)

            if field.id == 'url' and strings.slugify(field.label) == 'site-web-url':
                web_site_by_id[poi._id] = field.value
            elif field.id == 'url' and web_site_by_id.get(poi._id) is None:
                web_site_by_id[poi._id] = field.value

    multimodal_info_services = model.Poi.sort_and_paginate_pois_list(
        ctx,
        None,
        multimodal_info_services_by_id,
        multimodal_info_services = True,
        )

    return templates.render(
        ctx,
        '/list.mako',
        data = data,
        errors = errors,
        ids_by_territory_id = ids_by_territory_id,
        inputs = inputs,
        mode = mode,
        multimodal_info_services = multimodal_info_services,
        ids_by_niveau = ids_by_niveau,
        transport_types_by_id = transport_types_by_id,
        web_site_by_id = web_site_by_id,
        **non_territorial_search_data)


def init_base(ctx, params):
    inputs = dict(
        container_base_url = params.get('container_base_url'),
        custom_css_url = params.get('custom_css'),
        gadget = params.get('gadget'),
        territory_kind = params.getall('territory_kind'),
        )

    ctx.container_base_url = container_base_url = inputs['container_base_url'] or None
    gadget_id, error = conv.input_to_int(inputs['gadget'])
    ctx.gadget_id = gadget_id
    if error is not None or gadget_id is None:
        gadget_id = None
        if container_base_url is not None:
            # Ignore container site when no gadget ID is given.
            container_base_url = None

    for param_visibility_name in model.Poi.get_visibility_params_names(ctx):
        inputs[param_visibility_name] = conf.get(param_visibility_name) or params.get(param_visibility_name)
        param_visibility, error = conv.pipe(
            conv.guess_bool,
            conv.default(False),
            )(inputs[param_visibility_name], state = ctx)
        if error is not None:
            raise wsgihelpers.bad_request(ctx, explanation = ctx._('Error for "{0}" parameter: {1}').format(
                param_visibility_name, error))
        setattr(ctx, param_visibility_name, param_visibility)

    ctx.custom_css_url, error = conv.pipe(
        conv.cleanup_line,
        conv.empty_to_none,
        conv.make_input_to_url(),
        )(inputs['custom_css_url'], state = ctx)
    if error is not None:
        ctx.custom_css_url = None

    ctx.autocompleter_territories_kinds = [
        territory_kind
        for territory_kind in inputs['territory_kind']
        if territory_kind in conf['autocompleter_territories_kinds']
        ] or conf['autocompleter_territories_kinds']

    return inputs


@wsgihelpers.wsgify
@ramdb.ramdb_based
def kml(req):
    ctx = contexts.Ctx(req)

    params = req.GET
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        bbox = params.get('bbox'),
        context = params.get('context'),
        current = params.get('current'),
        ))

    clusters, errors = conv.pipe(
        conv.inputs_to_pois_layer_data,
        conv.default_pois_layer_data_bbox,
        conv.layer_data_to_clusters,
        )(inputs, state = ctx)
    if errors is not None:
        raise wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))

    req.response.content_type = 'application/vnd.google-earth.kml+xml; charset=utf-8'
    return templates.render(
        ctx,
        '/kml.mako',
        clusters = clusters,
        inputs = inputs,
        )


@wsgihelpers.wsgify
@ramdb.ramdb_based
def mail(req):
    ctx = contexts.Ctx(req)

    params = req.GET
    inputs = dict(
        email = params.get('email'),
        subject = params.get('subject'),
        body = params.get('body'),
        callback_url = params.get('callback-url'),
        )

    data, errors = conv.inputs_to_mail_data(inputs, state = ctx)
    if errors is not None:
        raise wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    data['to'] = conf['data_email']
    smtp = smtplib.SMTP(conf['smtp_server'])
    smtp.sendmail(
        data['from'],
        data['to'],
        unicode(templates.render(ctx, '/contact-mail.mako', data = data).strip()).encode('utf-8')
        )
    smtp.quit()
    ctx.session['message'] = ctx._('Your email has been sent')
    ctx.session.save()
    return wsgihelpers.redirect(
        ctx,
        location = urls.get_url(ctx, data['callback_url'])
        )


def make_router():
    """Return a WSGI application that dispatches requests to controllers """
    return urls.make_router(
        ('GET', '^/?$', index),
        ('GET', '^/(?P<page>(about|contact|help|contribute|data))/?$', static),
        ('GET', '^/accueil?$', index_home),
        ('GET', '^/api/v1/annuaire/csv/?$', csv),
        ('GET', '^/api/v1/annuaire/excel/?$', excel),
        ('GET', '^/api/v1/annuaire/kml/?$', kml),
        ('GET', '^/api/v1/categories/autocomplete/?$', autocomplete_category),
        ('GET', '^/api/v1/couverture/csv/?$', geographical_coverage_csv),
        ('GET', '^/api/v1/couverture/excel/?$', geographical_coverage_excel),
        ('GET', '^/api/v1/names/autocomplete/?$', autocomplete_names),
        ('GET', '^/export/?$', index_export),
        ('GET', '^/export/annuaire/csv/?$', export_directory_csv),
        ('GET', '^/export/annuaire/excel/?$', export_directory_excel),
        ('GET', '^/export/annuaire/geojson/?$', export_directory_geojson),
        ('GET', '^/export/annuaire/kml/?$', export_directory_kml),
        ('GET', '^/export/couverture/csv/?$', export_geographical_coverage_csv),
        ('GET', '^/export/couverture/excel/?$', export_geographical_coverage_excel),
        ('GET', '^/feed/?$', feed),
        ('GET', '^/gadget/?$', index_gadget),
        ('GET', '^/liste/?$', index_list),
        ('GET', '^/mail/?$', mail),
        ('GET', '^/organismes/?$', poi),
        ('GET', '^/organismes/(?P<poi_id>[a-z0-9]{24})/?$', poi),
        ('GET', '^/organismes/(?P<slug>[^/]+)/(?P<poi_id>[a-z0-9]{24})/?$', poi),
        ('GET', '^/passim.csv/?$', export_directory_csv, {'accept': 1}),
        )


@wsgihelpers.wsgify
@ramdb.ramdb_based
def poi(req):
    ctx = contexts.Ctx(req)

    params = req.params
    inputs = init_base(ctx, params)
    inputs.update(model.Poi.extract_search_inputs_from_params(ctx, params))
    inputs.update(dict(
        page = params.get('page'),
        poi_id = req.urlvars.get('poi_id'),
        poi_index = params.get('poi_index'),
        slug = req.urlvars.get('slug'),
        ))

    data, errors = conv.pipe(
        conv.merge(
            conv.inputs_to_pois_list_data,
            conv.struct(
                dict(
                    poi_id = conv.pipe(
                        conv.input_to_object_id,
                        conv.id_to_poi,
                        ),
                    ),
                default = 'drop',
                keep_none_values = True,
                ),
            ),
        conv.rename_item('poi_id', 'poi'),
        )(inputs, state = ctx)
    non_territorial_search_data = model.Poi.extract_non_territorial_search_data(ctx, data)
    if errors is not None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    if data['poi'] is None and data['poi_index'] is None:
        return wsgihelpers.bad_request(ctx, explanation = ctx._('Invalid POI ID'))

    if data['poi'] is None:
        territory = data['territory']
        pois_id_iter = model.Poi.iter_ids(
            ctx,
            territory = territory,
            **non_territorial_search_data)

        poi_by_id = dict(
            (poi._id, poi)
            for poi in (
                model.Poi.instance_by_id.get(poi_id)
                for poi_id in pois_id_iter
                )
            if poi is not None
            )

        pager = pagers.Pager(
            item_count = len(poi_by_id),
            page_max_size = conf['pager.page_max_size'],
            page_number = data['page_number'] if data['poi_index'] is None else (
                data['poi_index'] / conf['pager.page_max_size']
                ) + 1,
            )
        pager.items = model.Poi.sort_and_paginate_pois_list(
            ctx,
            pager,
            poi_by_id,
            territory = territory,
            **non_territorial_search_data
            )
        data['poi'] = pager.items[min((data['poi_index'] - 1) % conf['pager.page_max_size'], len(pager.items) - 1)]
    else:
        slug = data['poi'].slug
        if inputs['slug'] != slug:
            if ctx.container_base_url is None or ctx.gadget_id is None:
                raise wsgihelpers.redirect(ctx, location = urls.get_url(ctx, 'organismes', slug, data['poi']._id))
            # In gadget mode, there is no need to redirect.

    return templates.render(
        ctx,
        '/poi.mako',
        data = data,
        inputs = inputs,
        poi = data['poi'],
        )


@wsgihelpers.wsgify
def static(req):
    ctx = contexts.Ctx(req)
    page = req.urlvars.get('page')

    inputs = dict(
        message = ctx.session.get('message')
        )
    data, errors = conv.struct(
        {
            'message': conv.cleanup_line,
            },
        keep_none_values = True,
        )(inputs, state = ctx)
    if errors is not None:
        raise wsgihelpers.bad_request(ctx, explanation = ctx._('Error: {0}').format(errors))
    if data['message'] is not None:
        ctx.session.delete()
    return templates.render(ctx, '/{0}.mako'.format(page), data = data)
