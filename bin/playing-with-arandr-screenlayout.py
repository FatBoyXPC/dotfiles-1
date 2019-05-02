#!/usr/bin/env python3

from pprint import pprint
import screenlayout.xrandr
from edid import Edid
from screenlayout.auxiliary import Position, NORMAL, InadequateConfiguration

xrandr = None
def main():
    global xrandr
    xrandr = screenlayout.xrandr.XRandR()
    xrandr.load_from_x()

    outputs_by_name = xrandr.state.outputs
    for output in outputs_by_name.values():
        activate_output(output, make_active=False)

    def find_output(monitor_name):
        output_name = find_monitor(monitor_name)
        return outputs_by_name[output_name] if output_name else None

    benq_output = find_output('BenQ XL2420T')
    laptop_output = outputs_by_name['eDP1']
    if benq_output:
        activate_output(benq_output, make_active=True)
    else:
        activate_output(laptop_output, make_active=True)


    print(" ".join(xrandr.configuration.commandlineargs()))

def activate_output(output, make_active):
    output_config = xrandr.configuration.outputs[output.name]
    output_config.active = make_active
    if make_active:
        # Copied from
        # /usr/lib/python3.7/site-packages/screenlayout/widget.py
        # ARandRWidget::set_active
        output_config.position = Position((0, 0))

        virtual_state = xrandr.state.virtual
        for mode in output.modes:
            # determine first possible mode
            if mode[0] <= virtual_state.max[0] and mode[1] <= virtual_state.max[1]:
                first_mode = mode
                break
            else:
                raise InadequateConfiguration(
                    "Smallest mode too large for virtual.")

        output_config.mode = first_mode
        output_config.rotation = NORMAL

def get_edids():
    output = xrandr._output("--verbose")
    display = None
    edid = None
    edids_by_display = {}

    for line in output.split('\n'):
        if 'connected' in line:
            display = line.split(' ')[0]
        elif line.startswith('\tEDID'):
            edid = ""
        elif line.startswith('\t\t') and edid is not None:
            edid += line.strip()
        elif not line.startswith('\t\t') and edid is not None:
            edid = bytes([ int("".join(pair), 16) for pair in zip(*[iter(edid)]*2) ])
            edids_by_display[display] = Edid(edid)
            edid = None
            display = None

    return edids_by_display

def find_monitor(monitor_name):
    for display_name, edid in get_edids().items():
        if edid.name == monitor_name:
            return display_name

    return None

if __name__ == "__main__":
    main()
