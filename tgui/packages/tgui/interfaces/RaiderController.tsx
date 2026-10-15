import {
  Button,
  LabeledList,
  NumberInput,
  Section,
} from 'tgui-core/components';

import { useBackend } from '../backend';
import { Window } from '../layouts';

type RaiderControllerData = {
  limited: boolean;
  blocked: boolean;
  disabled: boolean;
  time_limit_hours: number;
  devastation_cap: number;
  heavy_impact_cap: number;
  light_impact_cap: number;
  block_chem_smoke: boolean;
  block_foam: boolean;
  block_combustible_flood: boolean;
};

export function RaiderController() {
  const { act, data } = useBackend<RaiderControllerData>();

  return (
    <Window width={480} height={380}>
      <Window.Content scrollable>
        <Section fill>
          <LabeledList>
            <LabeledList.Item label="Режим контроллера">
              <Button selected={data.blocked} onClick={() => act('block')}>
                ЗАПРЕТ
              </Button>
              <Button selected={data.limited} onClick={() => act('limit')}>
                ЛИМИТ
              </Button>
              <Button selected={data.disabled} onClick={() => act('disable')}>
                ВЫКЛ
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Порог времени игры">
              <NumberInput
                value={data.time_limit_hours}
                minValue={0}
                maxValue={1000}
                step={1}
                unit="ч"
                width="150px"
                onChange={(value) => act('set_time_limit', { hours: value })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Кап Devastation">
              <NumberInput
                value={data.devastation_cap}
                minValue={0}
                maxValue={100}
                step={1}
                width="150px"
                disabled={!data.limited}
                onChange={(value) =>
                  act('set_cap', { range: 'devastation', value })
                }
              />
            </LabeledList.Item>
            <LabeledList.Item label="Кап Heavy">
              <NumberInput
                value={data.heavy_impact_cap}
                minValue={0}
                maxValue={100}
                step={1}
                width="150px"
                disabled={!data.limited}
                onChange={(value) => act('set_cap', { range: 'heavy', value })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Кап Light">
              <NumberInput
                value={data.light_impact_cap}
                minValue={0}
                maxValue={100}
                step={1}
                width="150px"
                disabled={!data.limited}
                onChange={(value) => act('set_cap', { range: 'light', value })}
              />
            </LabeledList.Item>
            <LabeledList.Item label="Запрет дыма">
              <Button
                icon={data.block_chem_smoke ? 'power-off' : 'times'}
                selected={data.block_chem_smoke}
                onClick={() => act('toggle_chem_smoke')}
              >
                {data.block_chem_smoke ? 'Вкл' : 'Выкл'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Запрет пены">
              <Button
                icon={data.block_foam ? 'power-off' : 'times'}
                selected={data.block_foam}
                onClick={() => act('toggle_foam')}
              >
                {data.block_foam ? 'Вкл' : 'Выкл'}
              </Button>
            </LabeledList.Item>
            <LabeledList.Item label="Запрет возгонки">
              <Button
                icon={data.block_combustible_flood ? 'power-off' : 'times'}
                selected={data.block_combustible_flood}
                onClick={() => act('toggle_combustible_flood')}
              >
                {data.block_combustible_flood ? 'Вкл' : 'Выкл'}
              </Button>
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Window.Content>
    </Window>
  );
}
