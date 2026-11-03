"""Intentionally failing CI evidence test. NEVER merge this branch into main."""


def test_pipeline_rejects_a_failing_test():
    assert False, "Intentional CI failure for the assignment screenshot"
