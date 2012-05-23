import argparse
import subprocess
import sys
import os

class Config:

    glam = None
    ocn = None
    atm = None
    wind = None
    clock = None
    data = None

class DoubleGyre(Config):
    
    glam = "glam-dg.cdl"
    ocn = "ocn_dg.cdl"
    atm = "atm_dg.cdl"
    wind = "windstress-1.3.cdl"
    clock = "clock-0-5yr-6.cdl"

class DoubleGyreFast(DoubleGyre):

    clock = "clock-0-10dy-6.cdl"

class SouthernOceanOnly(Config):

    glam = "glam-so-only.cdl"
    ocn = "ocn_so_only.cdl"
    atm = None
    wind = "windstress-avges.cdl"
    clock = "clock-0-5yr-3.cdl"
    data = ["soctopog.26deg.10km.new.nc", "avges.nc"]

class SouthernOceanOnlyFast(SouthernOceanOnly):

    clock = "clock-0-10dy-3.cdl"
    
class SouthernOcean(Config):

    glam = "glam-so.cdl"
    ocn = "ocn_so.cdl"
    atm = "atm_so.cdl"
    wind = "windstress-1.5.cdl"
    clock = "clock-100-5yr-3.cdl"
    data = ["soctopog.26deg.10km.new.nc", 
            "lastday_so_ocn.nc", 
            "lastday_so_atm.nc",
            "lastday_so_aml.nc",
            "lastday_so_oml.nc"]

class SouthernOceanTau(SouthernOcean):

    wind = "windstress-1.5-udiff.cdl"

class SouthernOceanFast(SouthernOcean):

    clock = "clock-100yr-10dy-3.cdl"

class SouthernOceanTauFast(SouthernOceanTau):

    clock = "clock-100yr-10dy-3.cdl"

configs = {"dg": DoubleGyre,
           "dg_fast": DoubleGyreFast,
           "so_only": SouthernOceanOnly,
           "so_only_fast": SouthernOceanOnlyFast,
           "so": SouthernOcean,
           "so_fast": SouthernOceanFast,
           "so_tau": SouthernOceanTau,
           "so_tau_fast": SouthernOceanTauFast,
           }

def setup_from_config(config, setup_dir):
    os.system("mkdir -p %s" % setup_dir)
    os.system("cp data/glam/%s %s/glam.cdl" % (config.glam, setup_dir))
    os.system("cp data/basin/%s %s/ocn_basin.cdl" % (config.ocn, setup_dir))
    if config.atm:
        os.system("cp data/basin/%s %s/atm_basin.cdl" % (config.atm, setup_dir))
    os.system("cp data/windstress/%s %s/windstress.cdl" % (config.wind, setup_dir))
    os.system("cp data/clocks/%s %s/clock.cdl" % (config.clock, setup_dir))
    if config.data:
        for filename in config.data:
            os.system("cp data/nc_files/%s %s/" % (filename, setup_dir))

def setup_from_dir(input_dir, setup_dir):
    # Take the key files from the input directory and move them to the work directory
    os.system("mkdir -p %s" % setup_dir)
    os.system("cp %s/*.cdl %s/" % (input_dir, setup_dir))
    os.system("cp %s/*.nc %s/" % (input_dir, setup_dir))

stage_from_input = setup_from_dir

def preprocess_stage(stage_dir):
    # Preprocess the input files in the work directory
    for file in os.listdir(stage_dir):
        if file.endswith(".cdl"):
            base = ".".join(file.split(".")[:-1])
            cmd = "ncgen %s/%s.cdl -o %s/%s.nc" % (stage_dir, base, stage_dir, base)
            print cmd
            os.system(cmd)

def run_model(stage_dir, output_dir, exe, num_threads):
    # Run the model
    os.system("mkdir -p %s" % output_dir)
    cmd = "OMP_NUM_THREADS=%d %s %s %s" % (num_threads, exe, stage_dir, output_dir)
    #cmd = "valgrind %s %s %s" % (exe, stage_dir, output_dir)
    print cmd
    f = open("%s/stdout.txt" % output_dir, "w")
    p1 = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    out = p1.stdout
    while True:
        line = out.readline()
        if line:
            print line,
            f.write(line)
        else:
            break
    f.close()
    return p1.wait()

def run_single(input_dir, stage_dir, output_dir, exe, num_threads):

    stage_from_input(input_dir, stage_dir)

    preprocess_stage(stage_dir)

    return run_model(stage_dir, output_dir, exe, num_threads)

def update_clock(filename):
    if not os.path.exists(filename):
        ncfile = filename.rsplit(".", 1)[0] + ".nc"
        subprocess.call("ncdump %s > %s" % (ncfile, filename), shell=True)
    for line in open(filename):
        if line.strip().startswith("tini ="):
            tini = float(line.strip().split('=')[1][:-1])
        if line.strip().startswith("trun ="):
            trun = float(line.strip().split('=')[1][:-1])
    tini += trun
    f = open(filename + ".tmp", "w")
    for line in open(filename):
        if "tini" in line and "=" in line:
            line = "\ttini = %f;\n" % tini
        if "trun" in line and "=" in line:
            line = "\ttrun = %f;\n" % trun
        f.write(line)
    f.close()
    subprocess.call("mv %s.tmp %s" % (filename, filename), shell=True)

def update_basin(filename):
    """
    Take a basin .cdl file and rewrite the stage values to 
    look for the appropriate "*_lastday.nc" file.
    """
    if not os.path.exists(filename):
        base = ".".join(filename.split(".")[:-1])
        cmd = "ncdump %s.nc > %s.cdl" % (base, base)
        print cmd
        os.system(cmd)
    if not os.path.exists(filename):
        print "NCDUMP FAILED"
        return
    for line in open(filename):
        if line.strip().startswith("name ="):
            name = line.strip().split('"')[1].strip()
            break
    f = open(filename + ".tmp", "w")
    for line in open(filename):
        if "state" in line and "=" in line:
            new_state = "%s_%s_lastday.nc" % (name, line.split("_")[0].strip().replace("oml", "ml").replace("aml", "ml"))
            old = line.split('"')
            old[1] = new_state
            new_line = '"'.join(old)
            f.write(new_line)
        else:
            f.write(line)
    f.close()
    subprocess.call("mv %s.tmp %s" % (filename, filename), shell=True)

def main(exe, output_dir, num_threads, repeats, input_dir, exp):

    # Create the output directory
    if output_dir.endswith("/"):
        output_dir = output_dir[:-1]
    subprocess.call("mkdir -p %s" % output_dir, shell=True)

    # Setup the very first directory
    setup_dir= "%s/in-orig" % output_dir
    if input_dir is not None:
        if input_dir.endswith("/"):
            input_dir = input_dir[:-1]
        setup_from_dir(input_dir, setup_dir)
    elif exp is not None:
        setup_from_config(configs[exp], setup_dir)
    else:
        assert False

    # Copy everything from the input director into in-0
    subprocess.call("cp -R %s/in-orig %s/in-0" % (output_dir, output_dir), shell=True)

    # For each run:
    for run in range(repeats):
        # run single with in-n, out-n
        in_dir = "%s/in-%d" % (output_dir, run)
        stage_dir = "%s/stage-%d" % (output_dir, run)
        out_dir = "%s/out-%d" % (output_dir, run)
        ret = run_single(in_dir, stage_dir, out_dir, exe, num_threads)
        if ret != 0:
            print "FAILED in run", run
            sys.exit(ret)

        # take stage-n, out-n and create in-(n+1)
        next_in = "%s/in-%d" % (output_dir, run+1)
        subprocess.call("mkdir -p %s" % next_in, shell=True)
        subprocess.call("cp %s/* %s/" % (stage_dir, next_in), shell=True)
        subprocess.call("cp %s/*lastday.nc %s/" % (out_dir, next_in), shell=True)

        update_basin("%s/ocn_basin.cdl" % next_in)
        update_basin("%s/atm_basin.cdl" % next_in)
        update_clock("%s/clock.cdl" % next_in)


if __name__ == '__main__':

    parser = argparse.ArgumentParser(description='Run a Q-GCM experiment.',
                                     epilog="One of the -e or -i options must be provided.")
    parser.add_argument('-x', '--exe', dest="exe", type=str, default="src/q-gcm", required=True,
                        help='Q-GCM executable to use')
    parser.add_argument("-o", "--output", dest="output_dir", type=str, required=True,
                        help='Output directory')

    parser.add_argument('-n', '--num_threads', dest="num_threads", type=int, default=4,
                        help='The number of threads to use when running in parallel')
    parser.add_argument('-r', '--runs', dest="repeats", type=int, default=1,
                        help='The number of sequential runs to perform')

    parser.add_argument('-i', '--input', dest="input_dir", type=str,
                        help='Directory containing input files.')
    parser.add_argument('-e', '--exp', dest="exp", type=str, choices=configs,
                        help='A predefined experiment.')

    args = parser.parse_args()

    if args.exp is None and args.input_dir is None:
        parser.print_usage()
        print >> sys.stderr, "%s: error: One of the -e or -i options must be provided." % sys.argv[0]
        sys.exit(1)

    print "EXE", args.exe
    print "OUTPUT", args.output_dir
    print "NUM THREADS", args.num_threads
    print "REPEATS", args.repeats
    print "INPUT", args.input_dir
    print "EXP", args.exp

    main(args.exe, args.output_dir, args.num_threads, args.repeats, args.input_dir, args.exp)
