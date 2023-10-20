def crop_resize(clip: vs.VideoNode, apply_sar: bool = False, kernel: str = "Bicubic", **resize_args) -> vs.VideoNode:
    defaults = ["width", "height", "src_width", "src_height"]
    for i in defaults:
        if i not in resize_args:
            resize_args[i] = clip.height if defaults.index(i) % 2 else clip.width

    src_res = (resize_args["src_width"], resize_args["src_height"])
    out_res = [resize_args["width"], resize_args["height"]]

    props = clip.get_frame(0).props
    sar = [props.get("_SARNum", 1), props.get("_SARDen", 1)]

    if apply_sar and sar[0] != sar[1]:
        sar_f = sar[0] / sar[1]
        if sar_f > 1:
            out_res[0] = out_res[0] / sar_f
        else:
            out_res[1] = out_res[1] * sar_f
        sar[0], sar[1] = 1, 1

    src_dar = src_res[0] / src_res[1]
    out_dar = out_res[0] / out_res[1]

    if src_dar != out_dar:
        if src_dar > out_dar:
            src_res, out_res = src_res[::-1], out_res[::-1]
            src_shift, src_window = "src_left", "src_width"
        else:
            src_shift, src_window = "src_top", "src_height"

        scale = src_res[0] / out_res[0]
        crop = src_res[1] - (out_res[1] * scale)
        shift = crop / 2

        resize_args[src_shift] = resize_args.get(src_shift, 0) + shift
        resize_args[src_window] = resize_args[src_window] - crop

    out_clip = getattr(core.resize, kernel)(clip, **resize_args)
    return core.std.SetFrameProps(out_clip, _SARNum=sar[0], _SARDen=sar[1])
