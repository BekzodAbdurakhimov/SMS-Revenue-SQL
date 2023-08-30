DECLARE
  v_diff VARCHAR2(4000); -- ���������� ��� �������� ������������� �����
BEGIN
  FOR i in (SELECT t1.msisdn_to msisdn_to, MUST_SEND, ACTUAL_SENT, MUST_SEND - ACTUAL_SENT DIFFERENCE
  FROM (SELECT to_char(b.number_value) MSISDN_TO, count(1) MUST_SEND
          FROM bis.OBJ_EXTENTED_VALUE b -- ������� �� ������� ������
         where obj_id in (select d.obj_id
                            from (SELECT a.obj_id,
                                         case
                                           when to_char(sysdate, 'hh24') = '15' and -- ������� ��� ������� ����� ���� 8 ����� ���� �� �� ����� �� ��������� Gross adds
                                                a.varchar_value <> 'Gross adds' then
                                            15
                                           when to_char(sysdate, 'hh24') = '21' then -- ������� ��� ������� ����� ���� 21 ����� ������ �� ����� �� ��������� Gross adds
                                            21
                                         end values_X --obj_id
                                    FROM bis.OBJ_EXTENTED_VALUE a
                                   where a.group_id = 1541
                                     and a.end_date >= sysdate - 1
                                     and a.param_num = 4
                                     and a.varchar_value in
                                         ('Gross adds', -- ������ ���������
                                          'Revenue UZS',
                                          'Subs Info',
                                          'Prepaid',
                                          'ITC PL',
                                          'Postpaid',
                                          'Campaigns')) d
                           where d.values_X is not null)
           and b.number_value like '998%'
           and b.number_value not in ('99893874', '99893872', '99893854') -- ������ �� ������ ���� ������ �� ����
           and b.end_date > sysdate
           and b.group_id = 1541
         group by number_value) t1
  LEFT JOIN (select cc.MSISDN_TO, count(1) ACTUAL_SENT  -- ����� LEFT JOIN ��������� 2 ������� � �������� ������� 
               from (select c.*, --MSISDN_TO, count(1) count1
                            case
                              when to_char(sysdate,
                                           'hh24') = '15' and  -- ������� ��� ������� ����� ���� 8 ����� ���� �� �� ����� ��� ������������ � Gross adds
                                   c.msisdn_from <> 'Gross adds' then
                               15
                              when to_char(sysdate,
                                           'hh24') = '21' then -- ������� ��� ������� ����� ���� 21 ����� ������ �� ����� ��� ������������ � Gross adds
                               21
                            end values_X
                       from cnc.SMS_202308_1 c -- ������� �� ������� ������������ ���
                      where clnt_clnt_id = 0
                        and smgt_smgt_id = 2001
                        and msisdn_from in ('Gross adds',
                                            'Revenue UZS',
                                            'Subs Info',
                                            'Prepaid',
                                            'ITC PL',
                                            'Postpaid',
                                            'Campaigns')
                        and trunc(send_date) >= sysdate - 1) cc
              where cc.values_x is not null
              group by cc.MSISDN_TO) t2
    ON t1.msisdn_to = t2.msisdn_to) LOOP
      
      IF i.MUST_SEND <> i.ACTUAL_SENT THEN -- ��������� ���� ���-�� ��� � ������� � ������������ ��� �� ����� 
        v_diff := v_diff||i.msisdn_to||' '||i.MUST_SEND||' '||i.ACTUAL_SENT||' '||i.DIFFERENCE||CHR(10); -- �� ������� ��� ������
      ELSIF i.MUST_SEND = i.ACTUAL_SENT THEN -- ��������� ���� ���-�� ��� � ������� � ������F������ ��� ����� 
        v_diff := v_diff||i.msisdn_to||' '||i.MUST_SEND||' '||i.ACTUAL_SENT||' '||i.DIFFERENCE||CHR(10); -- �� ������� ��� ������
      END IF;
    END LOOP;

  -- ������� ������������� ������ �� �����
  DBMS_OUTPUT.PUT_LINE('Report:');
  DBMS_OUTPUT.PUT_LINE(v_diff);
END;
/


