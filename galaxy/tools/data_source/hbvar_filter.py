# TODO: Set dbkey to proper UCSC build, if known
import shutil
import tempfile

from six.moves.urllib.request import urlopen

from galaxy import datatypes


def exec_before_job(app, inp_data, out_data, param_dict, tool=None):
    """Sets the name of the data"""
    data_name = param_dict.get('name', 'HbVar query')
    data_type = param_dict.get('type', 'txt')
    if data_type == 'txt':
        data_type = 'interval'  # All data is TSV, assume interval
    name, data = next(iter(out_data.items()))
    data = app.datatypes_registry.change_datatype(data, data_type)
    data.name = data_name
    out_data[name] = data


def exec_after_process(app, inp_data, out_data, param_dict, tool=None, stdout=None, stderr=None):
    """Verifies the data after the run"""

    URL = param_dict.get('URL', None)
    URL = URL + '&_export=1&GALAXY_URL=0'
    if not URL:
        raise Exception('Datasource has not sent back a URL parameter')

    CHUNK_SIZE = 2**20  # 1Mb
    MAX_SIZE = CHUNK_SIZE * 100

    try:
        page = urlopen(URL)
    except Exception as exc:
        raise Exception('Problems connecting to %s (%s)' % (URL, exc))

    data = next(iter(out_data.values()))

    fp = open(data.file_name, 'wb')
    size = 0
    while 1:
        chunk = page.read(CHUNK_SIZE)
        if not chunk:
            break
        if size > MAX_SIZE:
            raise Exception('----- maximum datasize exceeded ---')
        size += len(chunk)
        fp.write(chunk)

    fp.close()
    # Set meta data, format file to be valid interval type
    if isinstance(data.datatype, datatypes.interval.Interval):
        data.set_meta(first_line_is_header=True)
        # check for missing meta data, if all there, comment first line and process file
        if not data.missing_meta():
            line_ctr = -1
            temp = tempfile.NamedTemporaryFile('w')
            temp_filename = temp.name
            temp.close()
            temp = open(temp_filename, 'w')
            int(data.metadata.chromCol)
            int(data.metadata.startCol)
            int(data.metadata.strandCol)

            for line in open(data.file_name, 'r'):
                line_ctr += 1

                fields = line.strip().split('\t')

                temp.write("%s\n" % '\t'.join(fields))

            temp.close()
            shutil.move(temp_filename, data.file_name)

        else:
            data = app.datatypes_registry.change_datatype(data, 'tabular')
    data.set_size()
    data.set_peek()
    app.model.context.add(data)
    app.model.context.flush()
