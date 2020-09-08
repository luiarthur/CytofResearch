# TODO

- Make a new directory vb-cb-sensitivity
    - Within, perform sensitivity analysis for data preprocessing
    - We currently have an arbitrary proportion, let's call it p. If for a
      marker j, either
        - more than p of the cells' expression levels for that marker are
          positive, or
        - more than p of the cells' expression levels for that marker are
          negative or missing, then we will discard that marker from the
          analysis.
    - We want to determine the model's sensitivity to p, by using
      p=(0.85, 0.9, 0.95, 0.99)?
