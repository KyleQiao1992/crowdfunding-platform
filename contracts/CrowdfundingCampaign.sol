// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title 众筹活动合约
 * @dev 使用状态机模式的单个众筹活动合约
 * @notice 本合约管理单个众筹活动的完整生命周期，状态流转如下：
 *         准备中(Preparing) -> 进行中(Active) -> 成功(Success)/失败(Failed) -> 已关闭(Closed)/已退款(Refunded)
 */
contract CrowdfundingCampaign {
    enum State {
        Preparing, // 准备中：活动已创建但尚未开始
        Active, // 进行中：活动正在接受资金贡献
        Success, // 成功：已达到筹款目标
        Failed, // 失败：截止时间已到但未达到目标
        Closed // 已关闭：资金已提取（仅适用于成功的活动）
    }

    ///@dev 活动的当前状态
    State public state;
    ///@dev 活动创建者地址（部署后不可变）
    address public immutable owner;
    //@dev 活动名称
    string public name;
    ///@dev 筹款目标金额（单位：wei）
    uint256 public goal;
    ///@dev 活动截止时间（Unix时间戳）（部署后不可变）
    uint256 public immutable deadline;
    ///@dev 已筹集的总金额
    uint256 public totalRaised;

    /// @dev 映射：从贡献者地址到其贡献金额
    mapping(address => uint256) public contributions;
    ///@dev 所有贡献者地址数组
    address[] public contributors;

    /// @dev 事件定义
    /// @notice 状态变更事件：当活动状态发生变化时触发
    event StateChanged(State oldState, State newState);
    /// @notice 贡献事件：当有用户贡献资金时触发
    event Contribution(address indexed contributor, uint256 amount);
    /// @notice 提取事件：当创建者提取资金时触发
    event Withdrawal(address indexed owner, uint256 amount);
    /// @notice 退款事件：当贡献者申请退款时触发
    event Refund(address indexed contributor, uint256 amount);

    /// @dev 修饰符定义
    /// @notice 仅所有者修饰符：确保只有活动创建者可以调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    /// @notice 状态检查修饰符：确保活动处于指定状态
    /// @param expectedState 要求的状态
    modifier inState(State expectedState) {
        require(state == expectedState, "Invalid state for this action");
        _;
    }

    /// @notice 未过期修饰符：确保活动尚未过期
    modifier notExpired() {
        require(block.timestamp < deadline, "Campaign has expired");
        _;
    }

    constructor(
        address _owner,
        string memory _name,
        uint256 _goal,
        uint256 _durationInDays
    ) {
        // 验证创建者地址不能为零地址
        require(_owner != address(0), "CrowdfundingCampaign: invalid owner");
        // 验证活动名称不能为空
        require(
            bytes(_name).length > 0,
            "CrowdfundingCampaign: name cannot be empty"
        );
        // 验证目标金额必须大于0
        require(_goal > 0, "CrowdfundingCampaign: goal must be positive");
        // 验证持续时间必须在1-90天之间
        require(
            _durationInDays > 0 && _durationInDays <= 90,
            "CrowdfundingCampaign: invalid duration"
        );
        owner = _owner;
        name = _name;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        state = State.Preparing;
    }

    /**
     * @dev 启动活动函数
     * @notice 只有创建者可以调用，且活动必须处于准备中状态
     * @notice 将活动状态从准备中变更为进行中
     */
    function start() external onlyOwner inState(State.Preparing) {
        state = State.Active;
        emit StateChanged(State.Preparing, State.Active);
    }


    

    /**
     * @dev 获取所有贡献者地址
     * @return 贡献者地址数组
     */
    function getContibutors() external view returns (address[] memory) {
        return contributors;
    }

    /**
     * @dev 获取贡献者总数
     * @return 唯一贡献者的数量
     */
    function getContributorCount() external view returns (uint256) {
        return contributors.length;
    }

    /**
     * @dev 检查活动是否正在进行中
     * @return 如果活动处于进行中状态则返回true，否则返回false
     */
    function isActive() public view returns (bool) {
        return state == State.Active;
    }

    /**
     * @dev 获取活动进度百分比
     * @return 进度百分比（0-100）
     * @notice 如果目标为0则返回0，如果超过100则返回100
     */
    function getProcess() external view returns (uint256) {
        // 如果目标为0，返回0
        if (goal == 0) {
            return 0;
        }

        // 计算进度百分比：已筹集金额 * 100 / 目标金额
        uint256 progress = (totalRaised * 100) / goal;
        // 如果超过100%，则返回100
        return progress > 100 ? 100 : progress;
    }
}
