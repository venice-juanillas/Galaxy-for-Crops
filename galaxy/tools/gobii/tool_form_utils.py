def get_field_components_options(dataset, field_name):
    options = []
    if dataset.metadata is None:
        return options
    if not hasattr(dataset.metadata, 'field_names'):
        return options
    if dataset.metadata.field_names is None:
        return options
    if field_name is None:
        # The expression validator that helps populate the select list of input
        # datsets in the icqsol_color_surface_field tool does not filter out
        # datasets with no field field_names, so we need this check.
        if len(dataset.metadata.field_names) == 0:
            return options
        field_name = dataset.metadata.field_names[0]
    field_components = dataset.metadata.field_components.get(field_name, [])
    for i, field_component in enumerate(field_components):
        options.append((field_component, field_component, i == 0))
    return options
