"""
Tests that groups are adjusted properly to avoid penalizing multiple groups without bug fixing changes.
"""

import pandas as pd
from compute_metrics import is_other_change
from compute_metrics import adjust_groups

def test_is_other_change():
    df = pd.DataFrame({
        'line':[1,2,3,4,5,6], 
        'fix':[True, True, False, False, False, False],
        'group':['g0', 'g1', 'g1', 'g2', 'g3', 'g3']})

    result = is_other_change(df)
    assert (result == pd.Series({'g0':False, 'g1':False, 'g2':True, 'g3':True})).all()

def test_adjusted_clustering_has_higher_score():
    pass

def test_adjust_groups():
    df = pd.DataFrame({
        'line':[1,2,3,4,5,6], 
        'fix':[True, True, False, False, False, False],
        'group':['g0', 'g1', 'g1', 'g2', 'g3', 'g3']})

    expected = pd.DataFrame({
        'line':[1,2,3,4,5,6], 
        'fix':[True, True, False, False, False, False],
        'group':['g0', 'g1', 'g1', 'o', 'o', 'o']})

    result = adjust_groups(df)

    assert result.equals(expected)