nextflow.enable.dsl=2

params.h1 = "data/H1_strain_1.hdf5"
params.l1 = "data/L1_strain_1.hdf5"

process MATCH_STRAIN {

    tag "$channel"

    input:
    tuple val(channel), path(strain)

    output:
    path "${channel}.csv"

    script:
    """
    python match_strain.py \
        --input-file $strain \
        --channel $channel \
        --output-file ${channel}.csv \
        --template-range 8-10 \
        --template-step 1.0
    """
}

process COINCIDENCE {

    input:
    path h1
    path l1

    output:
    path "coincident.csv"

    script:
    """
    python coincidence.py \
        --h1-trig $h1 \
        --l1-trig $l1 \
        --output-file coincident.csv
    """
}

process MAKE_INFERENCE {

    input:
    path events

    output:
    path "wf"

    script:
    """
    python make_inference.py \
        --coincident-events $events \
        --output-dir wf \
        --name-pattern run \
        --template-range 8-10 \
        --template-step 1.0
    """
}

workflow {

    strains = Channel.of(
        tuple("H1", file(params.h1)),
        tuple("L1", file(params.l1))
    )

    triggers = MATCH_STRAIN(strains)

    h1 = triggers.filter { it.name.startsWith("H1") }
    l1 = triggers.filter { it.name.startsWith("L1") }

    coincident = COINCIDENCE(h1, l1)

    MAKE_INFERENCE(coincident)
}
