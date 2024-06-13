FUNCTION zgera_codigo.
*"----------------------------------------------------------------------
*"*"Interface local:
*"  IMPORTING
*"     REFERENCE(NOME_TABELA) TYPE  CHAR20
*"  EXPORTING
*"     REFERENCE(NUMERO_SEQUENCIA) TYPE  ZID
*"     REFERENCE(ERRO) TYPE  BAPIRET2
*"----------------------------------------------------------------------

  DATA: lv_soma TYPE char5.

  CASE nome_tabela.
    WHEN 'ZFUNCIONARIO'.

      DATA(lv_numero_default) = '10000'.

      SELECT COUNT( * )
        FROM ZFuncionario.

      DATA(lv_resultado) = CONV char5( sy-dbcnt ).
*      lv_soma = lv_numero_default + lv_resultado.

      IF sy-dbcnt > 0.
        numero_sequencia = lv_numero_default + lv_resultado.
      ELSE.
        numero_sequencia = lv_numero_default.
      ENDIF.

    WHEN 'ZFUNCAO'.

      lv_numero_default = '20000'.

      SELECT *
        FROM Zfuncao
        INTO TABLE @DATA(lt_zfuncao).

      SORT lt_zfuncao BY id DESCENDING.

      READ TABLE lt_zfuncao INDEX 1 INTO DATA(lv_last_funcao).

      IF sy-dbcnt > 0.
        numero_sequencia = lv_last_funcao-id + 1.
      ELSE.
        numero_sequencia = lv_numero_default.
      ENDIF.

    WHEN 'ZDISCPLINA'.

      lv_numero_default = '30000'.

*      *** Ini - LUBARROS - Alteração da lógica de acréscimo no ID - 25.04.2024 15:11:28 ***

*      SELECT COUNT( * )
*        FROM zdiscplina.

      SELECT *
        FROM zdiscplina
        INTO TABLE @DATA(lt_zdiscplina).

      SORT lt_zdiscplina BY id_disciplina DESCENDING. "Inverte a tabela para pegar o último registro"

      READ TABLE lt_zdiscplina INDEX 1 INTO DATA(lv_last_discplina). "Pega a primeira linha, que é o último registro"

*      lv_resultado = CONV char5( sy-dbcnt ).
*      lv_soma = lv_numero_default + lv_resultado.

*      ** Fim - LUBARROS ***

      IF sy-dbcnt > 0.
*        numero_sequencia = lv_soma.
        numero_sequencia = lv_last_discplina-id_disciplina + 1.
      ELSE.
        numero_sequencia = lv_numero_default.
      ENDIF.

    WHEN 'ZTURMA'.

      lv_numero_default = '40000'.

      SELECT *
        FROM zturma
        INTO TABLE @DATA(lt_zturma).

      SORT lt_zturma BY id_turma DESCENDING.

      READ TABLE lt_zturma INDEX 1 INTO DATA(lv_last_turma).

      IF sy-dbcnt > 0.
        numero_sequencia = lv_last_turma-id_turma + 1.
      ELSE.
        numero_sequencia = lv_numero_default.
      ENDIF.

    WHEN 'ZNOTAS'.

      lv_numero_default = '50000'.

      SELECT *
        FROM znotas
        INTO TABLE @DATA(lt_znotas).

      SORT lt_znotas BY id DESCENDING.

      READ TABLE lt_znotas INDEX 1 INTO DATA(lv_last_nota).

      IF sy-dbcnt > 0.
        numero_sequencia = lv_last_nota-id + 1.
      ELSE.
        numero_sequencia = lv_numero_default.
      ENDIF.

    WHEN 'ZALUNOS'.

      lv_numero_default = '60000'.

      SELECT *
        FROM zalunos
        INTO TABLE @DATA(lt_zalunos).

      SORT lt_znotas BY id DESCENDING.

      READ TABLE lt_znotas INDEX 1 INTO DATA(lv_last_aluno).

      IF sy-dbcnt > 0.
        numero_sequencia = lv_last_aluno-id + 1.
      ELSE.
        numero_sequencia = lv_numero_default.
      ENDIF.

    WHEN 'ZFREQUENCIA'.

      lv_numero_default = '70000'.

      SELECT *
        FROM zfrequencia
        INTO TABLE @DATA(lt_zfrequencia).

      SORT lt_zfrequencia BY id DESCENDING.

      READ TABLE lt_zfrequencia INDEX 1 INTO DATA(lv_last_frequencia).

      IF sy-dbcnt > 0.
        numero_sequencia = lv_last_frequencia-id + 1.
      ELSE.
        numero_sequencia = lv_numero_default.
      ENDIF.

    WHEN OTHERS.

      erro-type = c_erro.
      erro-message = 'Tabela inexistente'.
      RETURN.

  ENDCASE.

  IF numero_sequencia IS NOT INITIAL.
    erro-type = c_sucesso.
    erro-message = 'Registro gerado com Sucesso'.
  ENDIF.

ENDFUNCTION.